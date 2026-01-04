from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserViewSet, PacienteViewSet, TipoAtendimentoViewSet, PacoteViewSet, AgendamentoViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'pacientes', PacienteViewSet)
router.register(r'tipos-atendimento', TipoAtendimentoViewSet)
router.register(r'pacotes', PacoteViewSet)
router.register(r'agendamentos', AgendamentoViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
