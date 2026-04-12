from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import models
from django.db.models import Q
from decimal import Decimal
from datetime import datetime, timedelta, time
from .models import User, Paciente, TipoAtendimento, Pacote, Agendamento, SolicitacaoAgendamento, UserRole
from .serializers import UserSerializer, PacienteSerializer, TipoAtendimentoSerializer, PacoteSerializer, AgendamentoSerializer, SolicitacaoAgendamentoSerializer, UserRoleSerializer
from .permissions import IsAdminRole, IsProfessionalOwnerOrAdmin, IsFinanceiroOrAdmin

class FinanceiroViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated, IsFinanceiroOrAdmin]

    @action(detail=False, methods=['get'])
    def status_pagamento(self, request):
        status_filtro = request.query_params.get('pago') # 'true' ou 'false'
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        queryset = Pacote.objects.all().select_related('paciente', 'profissional', 'tipo_atendimento')
        
        if status_filtro == 'true':
            # Totalmente pago (valor_pago >= valor_total)
            queryset = queryset.filter(valor_pago__gte=models.F('valor_total'))
            if start_date and end_date:
                queryset = queryset.filter(data_pagamento__date__range=[start_date, end_date])
        elif status_filtro == 'false':
            # Pendente (valor_pago < valor_total)
            queryset = queryset.filter(valor_pago__lt=models.F('valor_total'))
            
        serializer = PacoteSerializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def renovacoes(self, request):
        # Filtra pacotes ativos que ainda não foram renovados
        pacotes_ativos = Pacote.objects.filter(
            status=Pacote.Status.ATIVO,
            renovacao__isnull=True
        )
        proximos_renovacao = []
        
        for pacote in pacotes_ativos:
            total = pacote.quantidade_total
            # Conta sessões que já aconteceram ou estão marcadas como falta
            realizadas = pacote.agendamentos.filter(
                status__in=[Agendamento.Status.REALIZADO, Agendamento.Status.FALTA]
            ).count()
            
            # Sessões restantes para serem realizadas
            restantes = total - realizadas
            
            # Só considera renovação quando faltar 2 ou menos sessões
            # Se o pacote é pequeno (ex: 2 sessões), ele já entra na lista de renovação
            if total > 0 and restantes <= 2:
                serializer = PacoteSerializer(pacote)
                data = serializer.data
                data['sessoes_realizadas'] = realizadas
                proximos_renovacao.append(data)
                
        return Response(proximos_renovacao)

class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.is_superuser or (user.users_roles and user.users_roles.pode_gerenciar_usuarios):
            return User.objects.all()
        # Usuário comum só vê a si mesmo
        return User.objects.filter(id=user.id)
    
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        return [IsAuthenticated(), IsAdminRole()]

    def perform_create(self, serializer):
        serializer.save(criado_por=self.request.user)

    def perform_update(self, serializer):
        serializer.save(editado_por=self.request.user)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_active = False
        instance.save()
        return Response(status=status.HTTP_204_NO_CONTENT)

class PacienteViewSet(viewsets.ModelViewSet):
    queryset = Paciente.objects.all()
    serializer_class = PacienteSerializer
    permission_classes = [IsAuthenticated, IsProfessionalOwnerOrAdmin]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser or (user.users_roles and user.users_roles.visualizar_tudo):
            return Paciente.objects.all()
        return Paciente.objects.filter(
            Q(criado_por=user) | Q(profissional_responsavel=user)
        ).distinct()

    def perform_create(self, serializer):
        user = self.request.user
        extra_data = {'criado_por': user}
        # Se não pode visualizar tudo, ele é o responsável
        if user.users_roles and not user.users_roles.visualizar_tudo:
            extra_data['profissional_responsavel'] = user
        serializer.save(**extra_data)

    def perform_update(self, serializer):
        serializer.save(editado_por=self.request.user)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_active = False
        instance.save()
        return Response(status=status.HTTP_204_NO_CONTENT)

class TipoAtendimentoViewSet(viewsets.ModelViewSet):
    queryset = TipoAtendimento.objects.all()
    serializer_class = TipoAtendimentoSerializer
    
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        return [IsAuthenticated(), IsAdminRole()]

    def perform_create(self, serializer):
        serializer.save(criado_por=self.request.user)

    def perform_update(self, serializer):
        serializer.save(editado_por=self.request.user)

class PacoteViewSet(viewsets.ModelViewSet):
    queryset = Pacote.objects.all()
    serializer_class = PacoteSerializer
    permission_classes = [IsAuthenticated, IsProfessionalOwnerOrAdmin]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser or (user.users_roles and user.users_roles.visualizar_tudo):
            return Pacote.objects.all()
        # Retorna pacotes criados pelo profissional, de pacientes sob sua responsabilidade,
        # ou onde ele tenha pelo menos um agendamento vinculado.
        return Pacote.objects.filter(
            Q(criado_por=user) | 
            Q(paciente__profissional_responsavel=user) |
            Q(agendamentos__profissional=user)
        ).distinct()

    def perform_create(self, serializer):
        # Se um profissional foi enviado no JSON, usa ele. Caso contrário, usa o usuário logado se ele for profissional.
        profissional = serializer.validated_data.get('profissional')
        if not profissional and self.request.user.users_roles and self.request.user.users_roles.eh_profissional:
            profissional = self.request.user
            
        # Se na criação já tem data de pagamento, considera o valor_pago como o valor_total
        data_pagamento = serializer.validated_data.get('data_pagamento')
        valor_total = serializer.validated_data.get('valor_total')
        valor_pago = valor_total if data_pagamento else 0

        pacote = serializer.save(
            criado_por=self.request.user,
            profissional=profissional,
            valor_pago=valor_pago
        )

        # Lógica de Agendamento Automático
        if pacote.data_inicio and pacote.dias_semana:
            try:
                # dias_semana vem como "0,2,4" (0=segunda, 6=domingo no Python weekday())
                selected_days = [int(d) for d in pacote.dias_semana.split(',')]
                
                count = 0
                current_date = pacote.data_inicio
                
                # Horário para automação
                session_time = pacote.horario_atendimento or time(8, 0)

                while count < pacote.quantidade_total:
                    if current_date.weekday() in selected_days:
                        Agendamento.objects.create(
                            pacote=pacote,
                            profissional=profissional,
                            data_hora=datetime.combine(current_date, session_time),
                            status=Agendamento.Status.AGENDADO,
                            criado_por=self.request.user
                        )
                        count += 1
                    
                    current_date += timedelta(days=1)
            except Exception as e:
                # Log or handle error if needed
                print(f"Erro no agendamento automático: {e}")

    def perform_update(self, serializer):
        instance = self.get_object()
        nova_quantidade = serializer.validated_data.get('quantidade_total')
        
        # 1. SALVA A INSTÂNCIA PRIMEIRO (Para os cálculos seguintes)
        pacote = serializer.save(editado_por=self.request.user)

        # Se a quantidade mudou, precisamos ajustar os agendamentos
        if nova_quantidade is not None and nova_quantidade != instance.quantidade_total:
            total_atual = pacote.agendamentos.count()
            
            # CASO A: A quantidade DIMINUIU
            if nova_quantidade < instance.quantidade_total:
                agendamentos_consumidos = pacote.agendamentos.filter(
                    status__in=[Agendamento.Status.REALIZADO, Agendamento.Status.FALTA]
                ).count()
                
                limite_alvo = max(nova_quantidade, agendamentos_consumidos)
                remover_count = total_atual - limite_alvo
                
                if remover_count > 0:
                    ids_para_remover = pacote.agendamentos.filter(
                        status__in=[Agendamento.Status.ABERTO, Agendamento.Status.AGENDADO]
                    ).order_by('-data_hora', '-id').values_list('id', flat=True)[:remover_count]
                    Agendamento.objects.filter(id__in=ids_para_remover).delete()
            
            # CASO B: A quantidade AUMENTOU
            elif nova_quantidade > instance.quantidade_total:
                aumento_count = nova_quantidade - total_atual
                
                if aumento_count > 0 and pacote.data_inicio and pacote.dias_semana:
                    try:
                        selected_days = [int(d) for d in pacote.dias_semana.split(',')]
                        
                        # Descobrir a partir de que data começar a criar as novas sessões
                        ultimo_agendamento = pacote.agendamentos.order_by('-data_hora').first()
                        if ultimo_agendamento:
                            current_date = ultimo_agendamento.data_hora.date() + timedelta(days=1)
                        else:
                            current_date = pacote.data_inicio
                        
                        count = 0
                        # Horário para automação
                        session_time = pacote.horario_atendimento or time(8, 0)

                        while count < aumento_count:
                            if current_date.weekday() in selected_days:
                                Agendamento.objects.create(
                                    pacote=pacote,
                                    profissional=pacote.profissional,
                                    data_hora=datetime.combine(current_date, session_time),
                                    status=Agendamento.Status.AGENDADO,
                                    criado_por=self.request.user
                                )
                                count += 1
                            current_date += timedelta(days=1)
                    except Exception as e:
                        print(f"Erro ao criar novas sessões na atualização: {e}")

    @action(detail=True, methods=['post'])
    def registrar_pagamento(self, request, pk=None):
        pacote = self.get_object()
        valor_recebido = request.data.get('valor_pago')
        substituir = request.data.get('substituir', False)
        
        if valor_recebido is not None:
            try:
                valor_decimal = Decimal(str(valor_recebido).replace(',', '.'))
                
                if substituir:
                    # Substitui o valor total pago
                    pacote.valor_pago = valor_decimal
                else:
                    # Soma ao valor que já estava pago anteriormente
                    pacote.valor_pago += valor_decimal
                
                pacote.data_pagamento = datetime.now()
                pacote.save()
                return Response({
                    'status': 'Pagamento registrado com sucesso', 
                    'valor_total_pago': str(pacote.valor_pago),
                    'saldo_restante': str(pacote.valor_total - pacote.valor_pago)
                })
            except Exception as e:
                return Response({'error': 'Valor de pagamento inválido'}, status=status.HTTP_400_BAD_REQUEST)
        
        return Response({'error': 'Valor não informado'}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def agendamentos(self, request, pk=None):
        pacote = self.get_object()
        agendamentos = pacote.agendamentos.all()
        serializer = AgendamentoSerializer(agendamentos, many=True)
        return Response(serializer.data)

class AgendamentoViewSet(viewsets.ModelViewSet):
    queryset = Agendamento.objects.all()
    serializer_class = AgendamentoSerializer
    permission_classes = [IsAuthenticated, IsProfessionalOwnerOrAdmin]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser or (user.users_roles and user.users_roles.visualizar_tudo):
            return Agendamento.objects.all()
        return Agendamento.objects.filter(
            Q(criado_por=user) | Q(profissional=user) | Q(pacote__paciente__profissional_responsavel=user)
        ).distinct()

    def perform_create(self, serializer):
        # Se um profissional foi enviado no JSON, usa ele. Caso contrário, usa o usuário logado.
        profissional = serializer.validated_data.get('profissional', self.request.user)
        serializer.save(
            criado_por=self.request.user,
            profissional=profissional
        )

    def perform_update(self, serializer):
        serializer.save(editado_por=self.request.user)

class SolicitacaoAgendamentoViewSet(viewsets.ModelViewSet):

    queryset = SolicitacaoAgendamento.objects.all()

    serializer_class = SolicitacaoAgendamentoSerializer

    permission_classes = [IsAuthenticated]



    def get_queryset(self):

        user = self.request.user
        if user.is_superuser or (user.users_roles and user.users_roles.visualizar_tudo):
            return SolicitacaoAgendamento.objects.all().order_by('-data_criacao')

        return SolicitacaoAgendamento.objects.filter(

            Q(solicitante=user) | Q(profissional_solicitado=user)

        ).order_by('-data_criacao')



    def perform_create(self, serializer):

        serializer.save(solicitante=self.request.user)



    @action(detail=False, methods=['get'])
    def count_unread(self, request):
        user = request.user
        
        # Notifications relevant to me:
        # 1. Requests sent TO me that are PENDING and NOT SEEN (I need to see the new request)
        # 2. Requests sent BY me that are ACCEPTED/REJECTED and NOT SEEN (I need to see the response)
        
        qs = SolicitacaoAgendamento.objects.filter(
            Q(profissional_solicitado=user, status=SolicitacaoAgendamento.Status.PENDENTE, visto=False) |
            Q(solicitante=user, status__in=[SolicitacaoAgendamento.Status.ACEITO, SolicitacaoAgendamento.Status.RECUSADO], visto=False)
        )
        
        count = qs.count()
        return Response({'count': count})

    @action(detail=False, methods=['post'])
    def mark_as_read(self, request):
        user = request.user
        # Marks all relevant unseen notifications as seen
        qs = SolicitacaoAgendamento.objects.filter(
            Q(profissional_solicitado=user, status=SolicitacaoAgendamento.Status.PENDENTE, visto=False) |
            Q(solicitante=user, status__in=[SolicitacaoAgendamento.Status.ACEITO, SolicitacaoAgendamento.Status.RECUSADO], visto=False)
        )
        updated = qs.update(visto=True)
        return Response({'updated': updated})

    @action(detail=False, methods=['post'])
    def limpar_atendidas(self, request):
        user = request.user
        # Remove notificações que já foram respondidas (ACEITO ou RECUSADO)
        # relacionadas ao usuário logado (seja ele o solicitante ou o solicitado)
        qs = SolicitacaoAgendamento.objects.filter(
            Q(solicitante=user) | Q(profissional_solicitado=user),
            status__in=[SolicitacaoAgendamento.Status.ACEITO, SolicitacaoAgendamento.Status.RECUSADO]
        )
        deleted_count, _ = qs.delete()
        return Response({'deleted': deleted_count})

    @action(detail=True, methods=['post'])
    def responder(self, request, pk=None):
        solicitacao = self.get_object()
        acao = request.data.get('acao') # 'ACEITAR' or 'RECUSAR'
        
        if solicitacao.profissional_solicitado != request.user:
            return Response({'error': 'Você não tem permissão para responder a esta solicitação.'}, status=status.HTTP_403_FORBIDDEN)
            
        if solicitacao.status != SolicitacaoAgendamento.Status.PENDENTE:
             return Response({'error': 'Esta solicitação já foi respondida.'}, status=status.HTTP_400_BAD_REQUEST)

        if acao == 'ACEITAR':
            solicitacao.status = SolicitacaoAgendamento.Status.ACEITO
            # Update appointment
            agendamento = solicitacao.agendamento
            agendamento.profissional = request.user
            agendamento.save()
            solicitacao.save()
            return Response({'status': 'Solicitação aceita e agendamento atualizado.'})
            
        elif acao == 'RECUSAR':
            solicitacao.status = SolicitacaoAgendamento.Status.RECUSADO
            solicitacao.save()

            # Ao recusar, o agendamento volta para ABERTO (pendente) e sem profissional
            agendamento = solicitacao.agendamento
            agendamento.status = Agendamento.Status.ABERTO
            agendamento.profissional = None
            agendamento.save()

            return Response({'status': 'Solicitação recusada. O agendamento agora está pendente (Aberto).'})
        
        return Response({'error': 'Ação inválida. Use ACEITAR ou RECUSAR.'}, status=status.HTTP_400_BAD_REQUEST)

class RelatorioViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def financeiro(self, request):
        profissional_id = request.query_params.get('profissional_id')
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')

        if not profissional_id or not start_date or not end_date:
            return Response(
                {'error': 'Parâmetros profissional_id, start_date e end_date são obrigatórios.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Busca agendamentos onde o profissional é quem realizou OU é o dono do pacote
            appointments = Agendamento.objects.filter(
                Q(profissional_id=profissional_id) | Q(pacote__profissional_id=profissional_id),
                data_hora__date__range=[start_date, end_date],
                status=Agendamento.Status.REALIZADO
            ).select_related('pacote', 'profissional', 'pacote__profissional').distinct()

            detailed_list = []
            total_receita = Decimal('0.00')
            total_repasse = Decimal('0.00')
            total_studio = Decimal('0.00')

            for appt in appointments:
                # 1. Valor da sessão (Receita)
                valor_sessao = appt.pacote.valor_por_sessao
                
                PO = appt.pacote.profissional
                RP = appt.profissional
                
                # 2. Cálculo do Repasse Padrão do DONO (para definir a fatia do Studio)
                po_standard_repasse = Decimal('0.00')
                if PO:
                    if PO.valor_repasse_fixo and PO.valor_repasse_fixo > 0:
                        po_standard_repasse = PO.valor_repasse_fixo
                    elif PO.percentual_repasse and PO.percentual_repasse > 0:
                        po_standard_repasse = valor_sessao * (PO.percentual_repasse / Decimal('100.00'))
                
                # 3. Fatia do Studio (Sempre fixa baseada no contrato do DONO)
                lucro_studio = valor_sessao - po_standard_repasse
                
                # 4. Cálculo do Repasse para o Profissional do Relatório (profissional_id)
                repasse_final_profissional = Decimal('0.00')
                is_reposicao = False
                
                # Taxa de reposição do RP (se houver)
                rp_replacement_fee = Decimal('0.00')
                if RP and RP != PO:
                    if RP.valor_taxa_reposicao_fixo and RP.valor_taxa_reposicao_fixo > 0:
                        rp_replacement_fee = RP.valor_taxa_reposicao_fixo
                    elif RP.percentual_taxa_reposicao and RP.percentual_taxa_reposicao > 0:
                        rp_replacement_fee = valor_sessao * (RP.percentual_taxa_reposicao / Decimal('100.00'))

                if str(RP.id) == str(profissional_id):
                    # Caso A: O profissional do relatório REALIZOU o atendimento
                    if RP != PO:
                        is_reposicao = True
                        repasse_final_profissional = rp_replacement_fee
                    else:
                        # Atendimento normal (ele é o dono e ele realizou)
                        repasse_final_profissional = po_standard_repasse
                elif PO and str(PO.id) == str(profissional_id):
                    # Caso B: O profissional do relatório é o DONO, mas outro realizou (RP != PO)
                    is_reposicao = True
                    # O dono recebe o seu repasse padrão MENOS o que foi pago ao repositor
                    repasse_final_profissional = po_standard_repasse - rp_replacement_fee

                # Add to totals
                total_receita += valor_sessao
                total_repasse += repasse_final_profissional
                total_studio += lucro_studio

                # Calculate session progress
                total_sessions = appt.pacote.quantidade_total
                used_sessions = appt.pacote.agendamentos.filter(
                    status__in=[Agendamento.Status.REALIZADO, Agendamento.Status.FALTA]
                ).count()
                progresso = f"{used_sessions}/{total_sessions}"

                # Add to detailed list
                detailed_list.append({
                    'id': appt.id,
                    'data_hora': appt.data_hora,
                    'paciente': appt.pacote.paciente.complete_name,
                    'valor_sessao': str(valor_sessao),
                    'valor_repasse': str(repasse_final_profissional.quantize(Decimal('0.00'))),
                    'lucro_studio': str(lucro_studio.quantize(Decimal('0.00'))),
                    'valor_total_pacote': str(appt.pacote.valor_total),
                    'progresso_sessao': progresso,
                    'is_reposicao': is_reposicao,
                    'dono_pacote': PO.username if PO else "N/A",
                    'quem_realizou': RP.username if RP else "N/A"
                })

            return Response({
                'detalhes': detailed_list,
                'resumo': {
                    'total_receita': str(total_receita.quantize(Decimal('0.00'))),
                    'total_repasse': str(total_repasse.quantize(Decimal('0.00'))),
                    'total_studio': str(total_studio.quantize(Decimal('0.00')))
                }
            })

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['get'])
    def profissional(self, request):
        profissional_id = request.query_params.get('profissional_id')
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')

        if not profissional_id or not start_date or not end_date:
            return Response(
                {'error': 'Parâmetros profissional_id, start_date e end_date são obrigatórios.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Busca agendamentos onde o profissional é quem realizou OU é o dono do pacote
            appointments = Agendamento.objects.filter(
                Q(profissional_id=profissional_id) | Q(pacote__profissional_id=profissional_id),
                data_hora__date__range=[start_date, end_date],
                status__in=[Agendamento.Status.REALIZADO, Agendamento.Status.FALTA]
            ).order_by('data_hora').distinct()

            serializer = AgendamentoSerializer(appointments, many=True)
            
            # Vamos manter tudo o que retornou na query.
            total_realizado = appointments.filter(status=Agendamento.Status.REALIZADO).count()
            total_falta = appointments.filter(status=Agendamento.Status.FALTA).count()
            
            return Response({
                'agendamentos': serializer.data,
                'resumo': {
                    'total_realizado': total_realizado,
                    'total_falta': total_falta,
                    'total_geral': total_realizado + total_falta
                }
            })

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class UserRoleViewSet(viewsets.ModelViewSet):
    queryset = UserRole.objects.all()
    serializer_class = UserRoleSerializer
    
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        return [IsAuthenticated(), IsAdminRole()]