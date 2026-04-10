from rest_framework import permissions
from .models import User

class IsAdminRole(permissions.BasePermission):
    """Permite acesso a quem tem permissão de gerenciar usuários ou é superuser."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and (
            request.user.is_superuser or (request.user.users_roles and request.user.users_roles.pode_gerenciar_usuarios)
        )

class IsFinanceiroOrAdmin(permissions.BasePermission):
    """Permite acesso a quem tem permissão de financeiro ou é superuser/admin."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and (
            request.user.is_superuser or 
            (request.user.users_roles and (
                request.user.users_roles.pode_gerenciar_financeiro or 
                request.user.users_roles.pode_gerenciar_usuarios
            ))
        )

class IsProfessionalOwnerOrAdmin(permissions.BasePermission):
    """
    Regra: 
    - Se tem flag visualizar_tudo ou é superuser, vê tudo.
    - Caso contrário, só vê/edita o que é dele (Pacientes, Agendamentos, Pacotes).
    """
    def has_permission(self, request, view):
        user = request.user
        if not user.is_authenticated:
            return False
        
        # Se for uma ação de criação, verifica a flag específica
        if request.method == 'POST':
            role = user.users_roles
            if not role:
                return user.is_superuser
            
            from .models import Paciente, Pacote, Agendamento
            # Aqui precisaríamos saber qual o modelo da view, mas o DRF geralmente injeta a view
            # Vamos simplificar: se for Admin, pode tudo. Se não, checa as flags.
            if user.is_superuser or role.pode_gerenciar_usuarios: # Admin total
                return True
                
            # Mapeamento simples baseado no nome da View (pode ser melhorado)
            view_name = view.__class__.__name__
            if 'Paciente' in view_name:
                return role.pode_gerenciar_pacientes
            if 'Pacote' in view_name:
                return role.pode_gerenciar_pacotes
            if 'Agendamento' in view_name:
                return role.pode_gerenciar_agendamentos
            
        return True

    def has_object_permission(self, request, view, obj):
        user = request.user
        role = user.users_roles
        
        if user.is_superuser or (role and role.visualizar_tudo):
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
            # Verifica se o profissional tem agendamentos neste pacote
            from .models import Pacote
            if isinstance(obj, Pacote):
                return obj.agendamentos.filter(profissional=user).exists()
            
        return False
