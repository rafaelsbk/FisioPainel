from django.contrib.auth.models import AbstractUser
from django.db import models

class AuditModel(models.Model):
    criado_por = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, blank=True, related_name='%(class)s_criados')
    data_criacao = models.DateTimeField(auto_now_add=True)
    editado_por = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, blank=True, related_name='%(class)s_editados')
    data_ultima_edicao = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True

class User(AbstractUser, AuditModel):
    class Role(models.TextChoices):
        ADMIN = "ADMIN", "Admin"
        PROFISSIONAL = "PROFISSIONAL", "Profissional"

    role = models.CharField(max_length=50, choices=Role.choices, blank=True, null=True)
    telepone_number = models.CharField(max_length=20, blank=True, null=True)
    cpf = models.CharField(max_length=14, blank=True, null=True)
    
    # Profissional specific fields
    crefito = models.CharField(max_length=20, blank=True, null=True)
    percentual_repasse = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    valor_repasse_fixo = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    def __str__(self):
        return self.username

class Paciente(AuditModel):
    complete_name = models.CharField(max_length=255)
    address = models.CharField(max_length=255, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    numero_telefone = models.CharField(max_length=20, blank=True, null=True)
    cpf = models.CharField(max_length=14, blank=True, null=True)
    rg = models.CharField(max_length=20, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    profissional_responsavel = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, blank=True, related_name='pacientes', limit_choices_to={'role': User.Role.PROFISSIONAL})

    def __str__(self):
        return self.complete_name

class TipoAtendimento(AuditModel):
    nome_atendimento = models.CharField(max_length=100)

    def __str__(self):
        return self.nome_atendimento

class Pacote(AuditModel):
    class Status(models.TextChoices):
        ATIVO = "ATIVO", "Ativo"
        FINALIZADO = "FINALIZADO", "Finalizado"
        CANCELADO = "CANCELADO", "Cancelado"

    paciente = models.ForeignKey('Paciente', on_delete=models.CASCADE, related_name='pacotes')
    tipo_atendimento = models.ForeignKey('TipoAtendimento', on_delete=models.CASCADE, related_name='pacotes')
    quantidade_total = models.IntegerField()
    valor_total = models.DecimalField(max_digits=10, decimal_places=2)
    valor_por_sessao = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=50, choices=Status.choices, default=Status.ATIVO)
    data_pagamento = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Pacote {self.id} para {self.paciente.complete_name}"

class Agendamento(AuditModel):
    class Status(models.TextChoices):
        ABERTO = "ABERTO", "Aberto"
        AGENDADO = "AGENDADO", "Agendado"
        REALIZADO = "REALIZADO", "Realizado"
        FALTA = "FALTA", "Falta"
        CANCELADO = "CANCELADO", "Cancelado"
    
    class StatusRepasse(models.TextChoices):
        PENDENTE = "PENDENTE", "Pendente"
        PAGO = "PAGO", "Pago"

    pacote = models.ForeignKey('Pacote', on_delete=models.CASCADE, related_name='agendamentos')
    profissional = models.ForeignKey('User', on_delete=models.CASCADE, related_name='agendamentos', limit_choices_to={'role': User.Role.PROFISSIONAL}, null=True, blank=True)
    data_hora = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=50, choices=Status.choices, default=Status.ABERTO)
    valor_repasse_calculado = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    status_repasse = models.CharField(max_length=50, choices=StatusRepasse.choices, default=StatusRepasse.PENDENTE)

    def __str__(self):
        return f"Agendamento para {self.pacote.paciente.complete_name} com {self.profissional.username} em {self.data_hora}"
