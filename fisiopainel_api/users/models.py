from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.db.models import Q

class UserManager(BaseUserManager):
    def create_user(self, username, email=None, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(username, email, password, **extra_fields)

    def _create_user(self, username, email, password, **extra_fields):
        if not username:
            raise ValueError("The given username must be set")
        email = self.normalize_email(email)
        user = self.model(username=username, email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, username, email=None, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        # Tenta atribuir a role Administrador automaticamente
        try:
            admin_role = UserRole.objects.get(nome_cargo="Administrador")
            extra_fields.setdefault("users_roles", admin_role)
        except Exception:
            # Role ainda nao existe (primeira migracao), ignora
            pass

        return self._create_user(username, email, password, **extra_fields)

class AuditModel(models.Model):
    criado_por = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, blank=True, related_name='%(class)s_criados')
    data_criacao = models.DateTimeField(auto_now_add=True, null=True)
    editado_por = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, blank=True, related_name='%(class)s_editados')
    data_ultima_edicao = models.DateTimeField(auto_now=True, null=True)

    class Meta:
        abstract = True

class User(AbstractUser, AuditModel):
    objects = UserManager()

    users_roles = models.ForeignKey('UserRole', on_delete=models.SET_NULL, null=True, blank=True, related_name='users')
    telepone_number = models.CharField(max_length=20, blank=True, null=True)
    cpf = models.CharField(max_length=14, blank=True, null=True)
    
    # Profissional specific fields
    crefito = models.CharField(max_length=20, blank=True, null=True)
    percentual_repasse = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    valor_repasse_fixo = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    percentual_taxa_reposicao = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    valor_taxa_reposicao_fixo = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    def __str__(self):
        return self.username

class UserRole(AuditModel):
    nome_cargo = models.CharField(max_length=50, unique=True)
    ativo = models.BooleanField(default=True)
    
    # Permission flags
    pode_gerenciar_usuarios = models.BooleanField(default=False)
    pode_gerenciar_pacientes = models.BooleanField(default=False)
    pode_gerenciar_pacotes = models.BooleanField(default=False)
    pode_gerenciar_agendamentos = models.BooleanField(default=False)
    pode_gerenciar_tipos_atendimento = models.BooleanField(default=False)
    pode_gerenciar_financeiro = models.BooleanField(default=False)
    visualizar_tudo = models.BooleanField(default=False)
    eh_profissional = models.BooleanField(default=False)

    def __str__(self):
        return self.nome_cargo

class Paciente(AuditModel):
    complete_name = models.CharField(max_length=255)
    address = models.CharField(max_length=255, blank=True, null=True)
    cep = models.CharField(max_length=10, blank=True, null=True)
    estado = models.CharField(max_length=2, blank=True, null=True)
    cidade = models.CharField(max_length=100, blank=True, null=True)
    bairro = models.CharField(max_length=100, blank=True, null=True)
    numero = models.CharField(max_length=20, blank=True, null=True)
    complemento = models.CharField(max_length=100, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    numero_telefone = models.CharField(max_length=20, blank=True, null=True)
    cpf = models.CharField(max_length=14, blank=True, null=True)
    rg = models.CharField(max_length=20, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    profissional_responsavel = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, blank=True, related_name='pacientes')

    def __str__(self):
        return self.complete_name

class TelefonePaciente(AuditModel):
    paciente = models.ForeignKey(Paciente, on_delete=models.CASCADE, related_name='telefones')
    numero = models.CharField(max_length=20)

    def __str__(self):
        return f"{self.numero} ({self.paciente.complete_name})"

class TipoAtendimento(AuditModel):
    nome_atendimento = models.CharField(max_length=100)
    cor = models.CharField(max_length=7, default="#406657")
    ativo = models.BooleanField(default=True)

    def __str__(self):
        return self.nome_atendimento

class Pacote(AuditModel):
    class Status(models.TextChoices):
        ATIVO = "ATIVO", "Ativo"
        FINALIZADO = "FINALIZADO", "Finalizado"
        CANCELADO = "CANCELADO", "Cancelado"

    class FormaPagamento(models.TextChoices):
        DEBITO = "DEBITO", "Débito"
        CREDITO = "CREDITO", "Crédito"
        PIX = "PIX", "PIX"
        ESPECIE = "ESPECIE", "Espécie"
        OUTROS = "OUTROS", "Outros"

    paciente = models.ForeignKey('Paciente', on_delete=models.CASCADE, related_name='pacotes')
    profissional = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, blank=True, related_name='pacotes_responsaveis')
    tipo_atendimento = models.ForeignKey('TipoAtendimento', on_delete=models.CASCADE, related_name='pacotes')   
    quantidade_total = models.IntegerField()
    valor_total = models.DecimalField(max_digits=10, decimal_places=2)
    valor_por_sessao = models.DecimalField(max_digits=10, decimal_places=2)
    valor_pago = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    forma_pagamento = models.CharField(max_length=20, choices=FormaPagamento.choices, null=True, blank=True)
    status = models.CharField(max_length=50, choices=Status.choices, default=Status.ATIVO)
    data_pagamento = models.DateTimeField(null=True, blank=True)
    renovado_de = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='renovacao')
    
    # Scheduling fields
    data_inicio = models.DateField(null=True, blank=True)
    horario_atendimento = models.TimeField(null=True, blank=True)
    dias_semana = models.CharField(max_length=50, blank=True, null=True, help_text="Ex: 0,2,4 (seg, qua, sex)")

    def __str__(self):
        return f"Pacote {self.id} para {self.paciente.complete_name}"

class Agendamento(AuditModel):
    class Status(models.TextChoices):
        ABERTO = "ABERTO", "Aberto"
        AGENDADO = "AGENDADO", "Agendado"
        REALIZADO = "REALIZADO", "Realizado"
        FALTA = "FALTA", "Falta"
        REMARCADO = "REMARCADO", "Remarcado"
        CANCELADO = "CANCELADO", "Cancelado"
    
    class StatusRepasse(models.TextChoices):
        PENDENTE = "PENDENTE", "Pendente"
        PAGO = "PAGO", "Pago"

    pacote = models.ForeignKey('Pacote', on_delete=models.CASCADE, related_name='agendamentos')
    profissional = models.ForeignKey('User', on_delete=models.CASCADE, related_name='agendamentos', null=True, blank=True)
    data_hora = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=50, choices=Status.choices, default=Status.ABERTO)
    valor_repasse_calculado = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    status_repasse = models.CharField(max_length=50, choices=StatusRepasse.choices, default=StatusRepasse.PENDENTE)

    def __str__(self):
        return f"Agendamento para {self.pacote.paciente.complete_name} com {self.profissional.username} em {self.data_hora}"

class SolicitacaoAgendamento(AuditModel):
    class Status(models.TextChoices):
        PENDENTE = "PENDENTE", "Pendente"
        ACEITO = "ACEITO", "Aceito"
        RECUSADO = "RECUSADO", "Recusado"

    solicitante = models.ForeignKey('User', on_delete=models.CASCADE, related_name='solicitacoes_enviadas')
    profissional_solicitado = models.ForeignKey('User', on_delete=models.CASCADE, related_name='solicitacoes_recebidas')
    agendamento = models.ForeignKey('Agendamento', on_delete=models.CASCADE, related_name='solicitacoes')
    status = models.CharField(max_length=50, choices=Status.choices, default=Status.PENDENTE)
    mensagem = models.TextField(blank=True, null=True)
    visto = models.BooleanField(default=False)

    def __str__(self):
        return f"Solicitação de {self.solicitante.username} para {self.profissional_solicitado.username} - {self.status}"
