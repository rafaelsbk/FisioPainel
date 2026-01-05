from rest_framework import permissions
from .models import User

class IsAdminRole(permissions.BasePermission):
    """Permite acesso apenas a administradores."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and (
            request.user.is_staff or getattr(request.user, 'role', '') == User.Role.ADMIN
        )

class IsProfessionalOwnerOrAdmin(permissions.BasePermission):
    """
    Regra: 
    - Admin vê tudo.
    - Profissional só vê/edita o que é dele (Pacientes, Agendamentos, Pacotes).
    """
    def has_object_permission(self, request, view, obj):
        user = request.user
        if user.is_staff or getattr(user, 'role', '') == User.Role.ADMIN:
            return True
        
        # Regra universal: Se o usuário criou o registro, ele tem acesso
        if hasattr(obj, 'criado_por') and obj.criado_por == user:
            return True

        # Se for um Paciente, checa o profissional_responsavel
        if hasattr(obj, 'profissional_responsavel'):
            return obj.profissional_responsavel == user
            
        # Se for um Agendamento, checa o profissional
        if hasattr(obj, 'profissional'):
            return obj.profissional == user
            
        # Se for um Pacote, checa o profissional do paciente ou se há agendamentos do profissional
        if hasattr(obj, 'paciente') and hasattr(obj.paciente, 'profissional_responsavel'):
            if obj.paciente.profissional_responsavel == user:
                return True
            # Verifica se o profissional tem agendamentos neste pacote (específico para modelo Pacote)
            from .models import Pacote
            if isinstance(obj, Pacote):
                return obj.agendamentos.filter(profissional=user).exists()
            
        return False
