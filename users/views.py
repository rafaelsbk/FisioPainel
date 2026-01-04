from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import User, Paciente, TipoAtendimento, Pacote, Agendamento
from .serializers import UserSerializer, PacienteSerializer, TipoAtendimentoSerializer, PacoteSerializer, AgendamentoSerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_active = False
        instance.save()
        return Response(status=status.HTTP_204_NO_CONTENT)

class PacienteViewSet(viewsets.ModelViewSet):
    queryset = Paciente.objects.all()
    serializer_class = PacienteSerializer
    permission_classes = [IsAuthenticated]

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_active = False
        instance.save()
        return Response(status=status.HTTP_204_NO_CONTENT)

class TipoAtendimentoViewSet(viewsets.ModelViewSet):
    queryset = TipoAtendimento.objects.all()
    serializer_class = TipoAtendimentoSerializer
    permission_classes = [IsAuthenticated]

class PacoteViewSet(viewsets.ModelViewSet):
    queryset = Pacote.objects.all()
    serializer_class = PacoteSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=True, methods=['get'])
    def agendamentos(self, request, pk=None):
        pacote = self.get_object()
        agendamentos = pacote.agendamentos.all()
        serializer = AgendamentoSerializer(agendamentos, many=True)
        return Response(serializer.data)

    # @action(detail=True, methods=['post'], url_path='criar-agendamentos')
    # def criar_agendamentos(self, request, pk=None):
    #     pacote = self.get_object()
    #     qtd = pacote.quantidade_total
    #     
    #     agendamentos = []
    #     for _ in range(qtd):
    #         agendamentos.append(Agendamento(
    #             pacote=pacote,
    #             status=Agendamento.Status.ABERTO,
    #         ))
    #     
    #     Agendamento.objects.bulk_create(agendamentos)
    #     return Response({'status': 'Agendamentos criados com sucesso'}, status=status.HTTP_201_CREATED)

class AgendamentoViewSet(viewsets.ModelViewSet):
    queryset = Agendamento.objects.all()
    serializer_class = AgendamentoSerializer
    permission_classes = [IsAuthenticated]
