# FisioPainel 🏥

O **FisioPainel** é um ecossistema de gestão para clínicas de fisioterapia, projetado para oferecer controle total aos administradores e uma ferramenta ágil de trabalho para os profissionais (fisioterapeutas/personals).

## 🚀 Funcionalidades Implementadas

### 🔐 Segurança e Acesso (RBAC)
- **Multi-nível:** Diferenciação completa entre `Administrador` e `Profissional`.
- **Autenticação Segura:** Login via JWT (JSON Web Tokens) com senhas criptografadas (PBKDF2).
- **Visibilidade Inteligente:** Profissionais visualizam apenas seus próprios dados e pacotes vinculados, enquanto administradores possuem visão global.

### 📅 Gestão de Atendimentos
- **Agenda Dinâmica:** Planejamento de sessões individual ou em massa.
- **Substituições:** Flexibilidade para um profissional agendar sessões para outro colega, com compartilhamento automático de acesso ao pacote.
- **Controle de Pacotes:** Monitoramento de sessões totais, realizadas e pendentes.

### 📝 Auditoria e Pacientes
- **Rastro Digital:** Registro automático de "Quem criou", "Quando criou", "Quem editou" e "Data da última edição" em todos os registros.
- **Ficha de Paciente:** Cadastro completo com histórico de pacotes e agendamentos.

## 🛠️ Stack Tecnológica

- **Backend:** Python 3.13 / Django 6.0 / Django REST Framework
- **App Mobile/Desktop:** Flutter / Dart
- **Banco de Dados:** PostgreSQL
- **Integração:** REST API com SimpleJWT

## ⚙️ Instalação e Execução

### 1. Servidor (API)
```bash
# Ativar ambiente virtual
.\fisiopainel_env\Scripts\activate

# Migrar banco de dados
python manage.py migrate

# Iniciar servidor
python manage.py runserver
```

### 2. Aplicativo (Frontend)
```bash
cd fisiopainel_app
flutter pub get
flutter run
```

## 📁 Organização do Repositório
- `/fisiopainel_api`: Núcleo de configuração do servidor Django.
- `/users`: Módulo principal contendo a lógica de negócios, modelos e permissões.
- `/fisiopainel_app`: Código-fonte completo do aplicativo Flutter.

---
Desenvolvido com foco em segurança, auditoria e facilidade de uso clínico.
