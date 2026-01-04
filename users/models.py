from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN = "ADMIN", "Admin"
        PROFISSIONAL = "PROFISSIONAL", "Profissional"

    # Base fields from AbstractUser: username, first_name, last_name, email, is_staff, is_active, date_joined
    
    role = models.CharField(max_length=50, choices=Role.choices, blank=True, null=True)
    telepone_number = models.CharField(max_length=20, blank=True, null=True)
    cpf = models.CharField(max_length=14, blank=True, null=True)
    
    # Profissional specific fields
    crefito = models.CharField(max_length=20, blank=True, null=True)
    percentual_repasse = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    valor_repasse_fixo = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    def __str__(self):
        return self.username

class Paciente(models.Model):
    # 'id' is added automatically by Django
    complete_name = models.CharField(max_length=255)
    address = models.CharField(max_length=255, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    numero_telefone = models.CharField(max_length=20, blank=True, null=True)
    cpf = models.CharField(max_length=14, blank=True, null=True)
    rg = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.complete_name

class TipoAtendimento(models.Model):
    nome_atendimento = models.CharField(max_length=100) # Note: 'Ex: RPG, Pilates, Traumato'

    def __str__(self):
        return self.nome_atendimento

class Pacote(models.Model):
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
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Pacote {self.id} para {self.paciente.complete_name}"

class Agendamento(models.Model):
    class Status(models.TextChoices):
        AGENDADO = "AGENDADO", "Agendado"
        REALIZADO = "REALIZADO", "Realizado"
        FALTA = "FALTA", "Falta"
        CANCELADO = "CANCELADO", "Cancelado"
    
    class StatusRepasse(models.TextChoices):
        PENDENTE = "PENDENTE", "Pendente"
        PAGO = "PAGO", "Pago"

    pacote = models.ForeignKey('Pacote', on_delete=models.CASCADE, related_name='agendamentos')
    profissional = models.ForeignKey('User', on_delete=models.CASCADE, related_name='agendamentos', limit_choices_to={'role': User.Role.PROFISSIONAL})
    data_hora = models.DateTimeField()
    status = models.CharField(max_length=50, choices=Status.choices, default=Status.AGENDADO)
    valor_repasse_calculado = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    status_repasse = models.CharField(max_length=50, choices=StatusRepasse.choices, default=StatusRepasse.PENDENTE)

    def __str__(self):
        return f"Agendamento para {self.pacote.paciente.complete_name} com {self.profissional.username} em {self.data_hora}"