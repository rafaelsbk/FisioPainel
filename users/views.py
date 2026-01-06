from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
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
