from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from decimal import Decimal
from .models import User, Paciente, TipoAtendimento, Pacote, Agendamento, SolicitacaoAgendamento
from .serializers import UserSerializer, PacienteSerializer, TipoAtendimentoSerializer, PacoteSerializer, AgendamentoSerializer, SolicitacaoAgendamentoSerializer
from .permissions import IsAdminRole, IsProfessionalOwnerOrAdmin

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    
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
        return Paciente.objects.all()

    def perform_create(self, serializer):
        user = self.request.user
        extra_data = {'criado_por': user}
        if getattr(user, 'role', '') == User.Role.PROFISSIONAL:
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
        if user.is_staff or getattr(user, 'role', '') == User.Role.ADMIN:
            return Pacote.objects.all()
        # Retorna pacotes criados pelo profissional, de pacientes sob sua responsabilidade,
        # ou onde ele tenha pelo menos um agendamento vinculado.
        from django.db.models import Q
        return Pacote.objects.filter(
            Q(criado_por=user) | 
            Q(paciente__profissional_responsavel=user) |
            Q(agendamentos__profissional=user)
        ).distinct()

    def perform_create(self, serializer):
        serializer.save(criado_por=self.request.user)

    def perform_update(self, serializer):
        serializer.save(editado_por=self.request.user)

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
            appointments = Agendamento.objects.filter(
                profissional_id=profissional_id,
                data_hora__date__range=[start_date, end_date],
                status=Agendamento.Status.REALIZADO
            ).select_related('pacote', 'profissional')

            detailed_list = []
            total_receita = Decimal('0.00')
            total_repasse = Decimal('0.00')
            total_studio = Decimal('0.00')

            for appt in appointments:
                # 1. Valor da sessão (Receita)
                valor_sessao = appt.pacote.valor_por_sessao
                
                # 2. Cálculo do Repasse
                repasse = Decimal('0.00')
                profissional = appt.profissional
                
                if profissional.valor_repasse_fixo and profissional.valor_repasse_fixo > 0:
                    repasse = profissional.valor_repasse_fixo
                elif profissional.percentual_repasse and profissional.percentual_repasse > 0:
                    repasse = valor_sessao * (profissional.percentual_repasse / Decimal('100.00'))
                
                # 3. Lucro Studio
                lucro_studio = valor_sessao - repasse

                # Add to totals
                total_receita += valor_sessao
                total_repasse += repasse
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
                    'valor_repasse': str(repasse.quantize(Decimal('0.00'))),
                    'lucro_studio': str(lucro_studio.quantize(Decimal('0.00'))),
                    'valor_total_pacote': str(appt.pacote.valor_total),
                    'progresso_sessao': progresso,
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
            appointments = Agendamento.objects.filter(
                profissional_id=profissional_id,
                data_hora__date__range=[start_date, end_date],
                status__in=[Agendamento.Status.REALIZADO, Agendamento.Status.FALTA]
            ).order_by('data_hora')

            serializer = AgendamentoSerializer(appointments, many=True)
            
            # Calculate totals
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
