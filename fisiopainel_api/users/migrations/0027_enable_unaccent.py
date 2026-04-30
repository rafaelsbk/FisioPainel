from django.db import migrations
from django.contrib.postgres.operations import UnaccentExtension

class Migration(migrations.Migration):

    dependencies = [
        ('users', '0026_telefonepaciente'),
    ]

    operations = [
        UnaccentExtension(),
    ]
