from django.contrib import admin
from .models import User, Paciente, TipoAtendimento, Pacote, Agendamento

admin.site.register(User)
admin.site.register(Paciente)
admin.site.register(TipoAtendimento)
admin.site.register(Pacote)
admin.site.register(Agendamento)