from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import User, Paciente, TipoAtendimento, Pacote, Agendamento, SolicitacaoAgendamento

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Add custom claims
        token['role'] = user.role
        token['username'] = user.username
        token['is_staff'] = user.is_staff
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data['role'] = self.user.role
        data['username'] = self.user.username
        return data

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    criado_por_nome = serializers.ReadOnlyField(source='criado_por.username')
    editado_por_nome = serializers.ReadOnlyField(source='editado_por.username')

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'password', 'first_name', 'last_name', 
            'role', 'telepone_number', 'cpf', 'crefito', 'percentual_repasse', 
            'valor_repasse_fixo', 'is_active', 'data_criacao', 'data_ultima_edicao',
            'criado_por_nome', 'editado_por_nome'
        ]

    def create(self, validated_data):
        password = validated_data.pop('password')
        role = validated_data.get('role')
        
        # Se for ADMIN, garantimos que tenha acesso ao painel admin do Django também
        if role == User.Role.ADMIN:
            validated_data['is_staff'] = True
            validated_data['is_superuser'] = True
            
        user = User.objects.create_user(**validated_data)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        role = validated_data.get('role', instance.role)

        # Se a role for alterada para ADMIN, atualiza permissões de staff
        if role == User.Role.ADMIN:
            instance.is_staff = True
            instance.is_superuser = True
        elif role == User.Role.PROFISSIONAL:
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

class PacienteSerializer(serializers.ModelSerializer):
    criado_por_nome = serializers.ReadOnlyField(source='criado_por.username')
    editado_por_nome = serializers.ReadOnlyField(source='editado_por.username')

    class Meta:
        model = Paciente
        fields = [
            'id', 'complete_name', 'address', 'email', 'numero_telefone', 
            'cpf', 'rg', 'is_active', 'profissional_responsavel',
            'data_criacao', 'data_ultima_edicao', 'criado_por_nome', 'editado_por_nome'
        ]

class TipoAtendimentoSerializer(serializers.ModelSerializer):
    criado_por_nome = serializers.ReadOnlyField(source='criado_por.username')
    editado_por_nome = serializers.ReadOnlyField(source='editado_por.username')

    class Meta:
        model = TipoAtendimento
        fields = '__all__'

class PacoteSerializer(serializers.ModelSerializer):
    criado_por_nome = serializers.ReadOnlyField(source='criado_por.username')
    editado_por_nome = serializers.ReadOnlyField(source='editado_por.username')

    class Meta:
        model = Pacote
        fields = '__all__'

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