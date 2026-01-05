from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import User, Paciente, TipoAtendimento, Pacote, Agendamento
from .serializers import UserSerializer, PacienteSerializer, TipoAtendimentoSerializer, PacoteSerializer, AgendamentoSerializer
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