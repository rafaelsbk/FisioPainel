from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Paciente, TipoAtendimento, Pacote, Agendamento

User = get_user_model()

class UserCreationTest(APITestCase):
    def test_create_user_with_password(self):
        from users.serializers import UserSerializer
        data = {
            "username": "newpro",
            "password": "securepassword",
            "role": "PROFISSIONAL"
        }
        serializer = UserSerializer(data=data)
        self.assertTrue(serializer.is_valid())
        user = serializer.save()
        self.assertTrue(user.check_password("securepassword"))
        self.assertEqual(user.role, "PROFISSIONAL")

class PacientePermissionTest(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_user(username='admin', password='password', role='ADMIN')
        self.pro1 = User.objects.create_user(username='pro1', password='password', role='PROFISSIONAL')
        self.pro2 = User.objects.create_user(username='pro2', password='password', role='PROFISSIONAL')

        self.paciente_admin = Paciente.objects.create(complete_name="Admin Patient", profissional_responsavel=self.admin)
        self.paciente_pro1 = Paciente.objects.create(complete_name="Pro1 Patient", profissional_responsavel=self.pro1)

    def test_admin_can_see_all(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/pacientes/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)

    def test_pro_sees_only_own(self):
        self.client.force_authenticate(user=self.pro1)
        response = self.client.get('/api/pacientes/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['complete_name'], "Pro1 Patient")

    def test_pro_create_auto_assign(self):
        self.client.force_authenticate(user=self.pro2)
        data = {"complete_name": "Pro2 New Patient"}
        response = self.client.post('/api/pacientes/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        patient = Paciente.objects.get(complete_name="Pro2 New Patient")
        self.assertEqual(patient.profissional_responsavel, self.pro2)

class DataFilteringTest(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_user(username='admin2', password='password', role='ADMIN')
        self.pro1 = User.objects.create_user(username='pro1_2', password='password', role='PROFISSIONAL')
        self.pro2 = User.objects.create_user(username='pro2_2', password='password', role='PROFISSIONAL')

        self.tipo = TipoAtendimento.objects.create(nome_atendimento="Pilates")
        
        self.pac_pro1 = Paciente.objects.create(complete_name="P1", profissional_responsavel=self.pro1)
        self.pac_pro2 = Paciente.objects.create(complete_name="P2", profissional_responsavel=self.pro2)

        self.pacote1 = Pacote.objects.create(paciente=self.pac_pro1, tipo_atendimento=self.tipo, quantidade_total=10, valor_total=100, valor_por_sessao=10)
        self.pacote2 = Pacote.objects.create(paciente=self.pac_pro2, tipo_atendimento=self.tipo, quantidade_total=10, valor_total=100, valor_por_sessao=10)

        self.agendamento1 = Agendamento.objects.create(pacote=self.pacote1, profissional=self.pro1)
        self.agendamento2 = Agendamento.objects.create(pacote=self.pacote2, profissional=self.pro2)

    def test_pro1_sees_only_own_pacotes(self):
        self.client.force_authenticate(user=self.pro1)
        response = self.client.get('/api/pacotes/')
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], self.pacote1.id)

    def test_pro1_sees_only_own_agendamentos(self):
        self.client.force_authenticate(user=self.pro1)
        response = self.client.get('/api/agendamentos/')
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], self.agendamento1.id)