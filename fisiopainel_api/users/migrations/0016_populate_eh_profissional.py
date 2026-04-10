from django.db import migrations

def populate_eh_profissional(apps, schema_editor):
    UserRole = apps.get_model('users', 'UserRole')

    # Profissional
    try:
        profissional_role = UserRole.objects.get(nome_cargo='Profissional')
        profissional_role.eh_profissional = True
        profissional_role.save()
    except UserRole.DoesNotExist:
        pass

    # Admin is usually not a 'Professional' who performs services, but they can be.
    # Usually we leave it to the user to choose. 
    # But for existing data, let's keep it simple.

def reverse_populate(apps, schema_editor):
    pass

class Migration(migrations.Migration):

    dependencies = [
        ('users', '0015_userrole_eh_profissional_and_more'),
    ]

    operations = [
        migrations.RunPython(populate_eh_profissional, reverse_populate),
    ]
