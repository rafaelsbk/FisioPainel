from django.db import migrations

def set_default_permissions(apps, schema_editor):
    UserRole = apps.get_model('users', 'UserRole')

    # Admin
    admin_role, _ = UserRole.objects.get_or_create(nome_cargo='Admin')
    admin_role.pode_gerenciar_usuarios = True
    admin_role.pode_gerenciar_pacientes = True
    admin_role.pode_gerenciar_pacotes = True
    admin_role.pode_gerenciar_agendamentos = True
    admin_role.pode_gerenciar_tipos_atendimento = True
    admin_role.visualizar_tudo = True
    admin_role.save()

    # Profissional
    profissional_role, _ = UserRole.objects.get_or_create(nome_cargo='Profissional')
    profissional_role.pode_gerenciar_usuarios = False
    profissional_role.pode_gerenciar_pacientes = False
    profissional_role.pode_gerenciar_pacotes = False
    profissional_role.pode_gerenciar_agendamentos = True
    profissional_role.pode_gerenciar_tipos_atendimento = False
    profissional_role.visualizar_tudo = False
    profissional_role.save()

    # Recepcionista
    recepcionista_role, _ = UserRole.objects.get_or_create(nome_cargo='Recepcionista')
    recepcionista_role.pode_gerenciar_usuarios = False
    recepcionista_role.pode_gerenciar_pacientes = True
    recepcionista_role.pode_gerenciar_pacotes = True
    recepcionista_role.pode_gerenciar_agendamentos = True
    recepcionista_role.pode_gerenciar_tipos_atendimento = False
    recepcionista_role.visualizar_tudo = True
    recepcionista_role.save()

def reverse_permissions(apps, schema_editor):
    pass

class Migration(migrations.Migration):

    dependencies = [
        ('users', '0013_userrole_pode_gerenciar_agendamentos_and_more'),
    ]

    operations = [
        migrations.RunPython(set_default_permissions, reverse_permissions),
    ]
