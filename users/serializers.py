from rest_framework import serializers
from .models import User, Paciente, TipoAtendimento, Pacote, Agendamento

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'role', 'telepone_number', 'cpf', 'crefito', 'percentual_repasse', 'valor_repasse_fixo', 'is_active']

class PacienteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Paciente
        fields = ['id', 'complete_name', 'address', 'email', 'numero_telefone', 'cpf', 'rg', 'created_at', 'is_active']

class TipoAtendimentoSerializer(serializers.ModelSerializer):
    class Meta:
        model = TipoAtendimento
        fields = '__all__'

class PacoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Pacote
        fields = '__all__'

class AgendamentoSerializer(serializers.ModelSerializer):
    nome_profissional = serializers.SerializerMethodField()
    
    class Meta:
        model = Agendamento
        fields = '__all__'

    def get_nome_profissional(self, obj):
        return obj.profissional.username if obj.profissional else None
