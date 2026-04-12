from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import User, Paciente, TipoAtendimento, Pacote, Agendamento, SolicitacaoAgendamento, UserRole, TelefonePaciente

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Add custom claims
        role = user.users_roles
        token['role'] = role.nome_cargo.upper() if role else None
        token['username'] = user.username
        token['is_staff'] = user.is_staff
        
        if role:
            token['permissions'] = {
                'pode_gerenciar_usuarios': role.pode_gerenciar_usuarios,
                'pode_gerenciar_pacientes': role.pode_gerenciar_pacientes,
                'pode_gerenciar_pacotes': role.pode_gerenciar_pacotes,
                'pode_gerenciar_agendamentos': role.pode_gerenciar_agendamentos,
                'pode_gerenciar_tipos_atendimento': role.pode_gerenciar_tipos_atendimento,
                'pode_gerenciar_financeiro': role.pode_gerenciar_financeiro,
                'visualizar_tudo': role.visualizar_tudo,
                'eh_profissional': role.eh_profissional,
            }
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        role = self.user.users_roles
        data['role'] = role.nome_cargo.upper() if role else None
        data['username'] = self.user.username
        if role:
            data['permissions'] = {
                'pode_gerenciar_usuarios': role.pode_gerenciar_usuarios,
                'pode_gerenciar_pacientes': role.pode_gerenciar_pacientes,
                'pode_gerenciar_pacotes': role.pode_gerenciar_pacotes,
                'pode_gerenciar_agendamentos': role.pode_gerenciar_agendamentos,
                'pode_gerenciar_tipos_atendimento': role.pode_gerenciar_tipos_atendimento,
                'pode_gerenciar_financeiro': role.pode_gerenciar_financeiro,
                'visualizar_tudo': role.visualizar_tudo,
                'eh_profissional': role.eh_profissional,
            }
        return data

class UserRoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserRole
        fields = [
            'id', 'nome_cargo', 'ativo', 
            'pode_gerenciar_usuarios', 'pode_gerenciar_pacientes', 
            'pode_gerenciar_pacotes', 'pode_gerenciar_agendamentos', 
            'pode_gerenciar_tipos_atendimento', 'pode_gerenciar_financeiro',
            'visualizar_tudo', 'eh_profissional'
        ]

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False, allow_blank=True)
    criado_por_nome = serializers.ReadOnlyField(source='criado_por.username')
    editado_por_nome = serializers.ReadOnlyField(source='editado_por.username')
    users_roles = UserRoleSerializer(read_only=True)
    users_roles_id = serializers.PrimaryKeyRelatedField(
        queryset=UserRole.objects.all(), source='users_roles', write_only=True, allow_null=True
    )

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'password', 'first_name', 'last_name', 
            'users_roles', 'users_roles_id', 'telepone_number', 'cpf', 'crefito', 'percentual_repasse', 
            'valor_repasse_fixo', 'percentual_taxa_reposicao', 'valor_taxa_reposicao_fixo', 'is_active', 'data_criacao', 'data_ultima_edicao',
            'criado_por_nome', 'editado_por_nome'
        ]

    def create(self, validated_data):
        password = validated_data.pop('password')
        user_role = validated_data.get('users_roles')
        
        # Se tem permissão de gerenciar usuários, damos acesso ao staff do Django
        if user_role and user_role.pode_gerenciar_usuarios:
            validated_data['is_staff'] = True
            validated_data['is_superuser'] = True # Mantemos superuser para quem pode gerenciar usuários
            
        user = User.objects.create_user(**validated_data)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        user_role = validated_data.get('users_roles', instance.users_roles)

        # Atualiza permissões de staff baseado na role
        if user_role and user_role.pode_gerenciar_usuarios:
            instance.is_staff = True
            instance.is_superuser = True
        else:
            instance.is_staff = False
            instance.is_superuser = False

        # Atualiza os outros campos
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        # Se uma nova senha foi enviada, faz o hash
        if password:
            instance.set_password(password)

        instance.save()
        return instance

class TelefonePacienteSerializer(serializers.ModelSerializer):
    class Meta:
        model = TelefonePaciente
        fields = ['id', 'numero']

class PacienteSerializer(serializers.ModelSerializer):
    criado_por_nome = serializers.ReadOnlyField(source='criado_por.username')
    editado_por_nome = serializers.ReadOnlyField(source='editado_por.username')
    telefones = TelefonePacienteSerializer(many=True, required=False)

    class Meta:
        model = Paciente
        fields = [
            'id', 'complete_name', 'address', 'cep', 'estado', 'cidade',
            'bairro', 'numero', 'complemento', 'email', 'numero_telefone',
            'cpf', 'rg', 'is_active', 'profissional_responsavel',
            'data_criacao', 'data_ultima_edicao', 'criado_por_nome', 'editado_por_nome',
            'telefones'
        ]

    def create(self, validated_data):
        telefones_data = validated_data.pop('telefones', [])
        paciente = Paciente.objects.create(**validated_data)
        for telefone_data in telefones_data:
            TelefonePaciente.objects.create(paciente=paciente, **telefone_data)
        return paciente

    def update(self, instance, validated_data):
        telefones_data = validated_data.pop('telefones', None)
        
        # Update Paciente fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        # Update Telefones if provided
        if telefones_data is not None:
            # Simple approach: replace all phones
            instance.telefones.all().delete()
            for telefone_data in telefones_data:
                TelefonePaciente.objects.create(paciente=instance, **telefone_data)
        
        return instance

class TipoAtendimentoSerializer(serializers.ModelSerializer):
    criado_por_nome = serializers.ReadOnlyField(source='criado_por.username')
    editado_por_nome = serializers.ReadOnlyField(source='editado_por.username')

    class Meta:
        model = TipoAtendimento
        fields = '__all__'

class PacoteSerializer(serializers.ModelSerializer):
    criado_por_nome = serializers.ReadOnlyField(source='criado_por.username')
    editado_por_nome = serializers.ReadOnlyField(source='editado_por.username')
    nome_profissional = serializers.ReadOnlyField(source='profissional.username')
    nome_paciente = serializers.ReadOnlyField(source='paciente.complete_name')
    nome_tipo_atendimento = serializers.ReadOnlyField(source='tipo_atendimento.nome_atendimento')

    class Meta:
        model = Pacote
        fields = [
            'id', 'paciente', 'profissional', 'tipo_atendimento',
            'quantidade_total', 'valor_total', 'valor_por_sessao',
            'valor_pago', 'status', 'data_pagamento', 'data_inicio', 'horario_atendimento', 'dias_semana',
            'renovado_de', 'criado_por_nome', 'editado_por_nome',
            'nome_profissional', 'nome_paciente', 'nome_tipo_atendimento'
        ]
    def validate(self, data):
        # Validação apenas na atualização (quando self.instance existe)
        if self.instance:
            nova_qtd = data.get('quantidade_total')
            if nova_qtd is not None and nova_qtd < self.instance.quantidade_total:
                # Conta sessões já consumidas (Realizadas ou Faltas)
                realizados = self.instance.agendamentos.filter(
                    status__in=['REALIZADO', 'FALTA']
                ).count()
                
                if nova_qtd < realizados:
                    raise serializers.ValidationError(
                        {"quantidade_total": "Número de sessões escolhidas é menor que o número de sessões realizadas."}
                    )
        return data

class AgendamentoSerializer(serializers.ModelSerializer):
    nome_profissional = serializers.SerializerMethodField()
    nome_paciente = serializers.SerializerMethodField()
    progresso_sessao = serializers.SerializerMethodField()
    valor_total_pacote = serializers.SerializerMethodField()
    criado_por_nome = serializers.ReadOnlyField(source='criado_por.username')
    editado_por_nome = serializers.ReadOnlyField(source='editado_por.username')
    
    class Meta:
        model = Agendamento
        fields = '__all__'

    def get_nome_profissional(self, obj):
        return obj.profissional.username if obj.profissional else None

    def get_nome_paciente(self, obj):
        return obj.pacote.paciente.complete_name if obj.pacote and obj.pacote.paciente else None

    def get_valor_total_pacote(self, obj):
        return str(obj.pacote.valor_total) if obj.pacote else None

    def get_progresso_sessao(self, obj):
        if not obj.pacote:
            return None
        # Count appointments for this package that are REALIZADO or FALTA (consumed sessions)
        # up to this one, or just total consumed vs total package
        
        # Option 1: "This is session X of Y" based on ID or date
        # Option 2: "X/Y Consumed" (general status)
        
        # Let's go with "X/Y" where X is the count of realized/falta appointments up to now.
        total_sessions = obj.pacote.quantidade_total
        
        # Get all appointments for this package ordered by date
        # We can't easily say "this is the 3rd one" without context of all of them.
        # But we can return "X/Y" where X is total used sessions for the package.
        
        used_sessions = obj.pacote.agendamentos.filter(
            status__in=[Agendamento.Status.REALIZADO, Agendamento.Status.FALTA]
        ).count()
        
        return f"{used_sessions}/{total_sessions}"

class SolicitacaoAgendamentoSerializer(serializers.ModelSerializer):
    solicitante_nome = serializers.ReadOnlyField(source='solicitante.username')
    profissional_solicitado_nome = serializers.ReadOnlyField(source='profissional_solicitado.username')
    agendamento_detalhes = AgendamentoSerializer(source='agendamento', read_only=True)

    class Meta:
        model = SolicitacaoAgendamento
        fields = '__all__'
        read_only_fields = ['solicitante', 'status', 'data_criacao', 'data_ultima_edicao']