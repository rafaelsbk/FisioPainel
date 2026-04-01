from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserViewSet, PacienteViewSet, TipoAtendimentoViewSet, PacoteViewSet, AgendamentoViewSet, SolicitacaoAgendamentoViewSet, RelatorioViewSet, UserRoleViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'user-roles', UserRoleViewSet)
router.register(r'pacientes', PacienteViewSet)
router.register(r'tipos-atendimento', TipoAtendimentoViewSet)
router.register(r'pacotes', PacoteViewSet)
router.register(r'agendamentos', AgendamentoViewSet)
router.register(r'solicitacoes-agendamento', SolicitacaoAgendamentoViewSet)
router.register(r'relatorios', RelatorioViewSet, basename='relatorios')

urlpatterns = [
    path('', include(router.urls)),
]
