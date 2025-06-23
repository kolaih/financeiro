import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(DespesasApp());
}

class DespesasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Despesas',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: TelaLogin(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Tela de Login ---
class TelaLogin extends StatefulWidget {
  @override
  _TelaLoginState createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  String? erro;

  Future<bool> login(String email, String senha) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('usuario_email');
    final savedSenha = prefs.getString('usuario_senha');
    return email == savedEmail && senha == savedSenha;
  }

  void tentarLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();
      final senha = senhaController.text.trim();

      final sucesso = await login(email, senha);

      if (sucesso) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DespesasPage(usuarioEmail: email)),
        );
      } else {
        setState(() {
          erro = 'Email ou senha inválidos';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (erro != null)
                Text(
                  erro!,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (v) => v == null || v.isEmpty ? 'Informe o email' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: senhaController,
                decoration: InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator:
                    (v) => v == null || v.isEmpty ? 'Informe a senha' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: tentarLogin, child: Text('Entrar')),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TelaCadastro()),
                  );
                },
                child: Text('Cadastrar novo usuário'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Tela de Cadastro ---
class TelaCadastro extends StatefulWidget {
  @override
  _TelaCadastroState createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final senhaConfController = TextEditingController();

  String? erro;

  Future<void> cadastrar(String email, String senha) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario_email', email);
    await prefs.setString('usuario_senha', senha);
  }

  void tentarCadastro() async {
    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();
      final senha = senhaController.text.trim();
      final senhaConf = senhaConfController.text.trim();

      if (senha != senhaConf) {
        setState(() {
          erro = 'As senhas não coincidem';
        });
        return;
      }

      await cadastrar(email, senha);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cadastro realizado com sucesso! Faça login.'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (erro != null)
                Text(
                  erro!,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (v) => v == null || v.isEmpty ? 'Informe o email' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: senhaController,
                decoration: InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator:
                    (v) => v == null || v.isEmpty ? 'Informe a senha' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: senhaConfController,
                decoration: InputDecoration(labelText: 'Confirme a senha'),
                obscureText: true,
                validator:
                    (v) => v == null || v.isEmpty ? 'Confirme a senha' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: tentarCadastro,
                child: Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Página principal do app despesas ---
class DespesasPage extends StatefulWidget {
  final String usuarioEmail;

  DespesasPage({required this.usuarioEmail});

  @override
  _DespesasPageState createState() => _DespesasPageState();
}

class _DespesasPageState extends State<DespesasPage> {
  List<Transacao> transacoes = [];
  double saldo = 0.0;

  final valorController = TextEditingController();
  final descricaoController = TextEditingController();
  final categoriaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  String get chaveStorage => 'transacoes_${widget.usuarioEmail}';

  void carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString(chaveStorage);
    if (dados != null) {
      final lista = jsonDecode(dados) as List;
      setState(() {
        transacoes = lista.map((e) => Transacao.fromJson(e)).toList();
        calcularSaldo();
      });
    }
  }

  void salvarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(transacoes.map((e) => e.toJson()).toList());
    prefs.setString(chaveStorage, json);
  }

  void adicionarTransacao(String tipo) {
    final valor = double.tryParse(valorController.text);
    final descricao = descricaoController.text.trim();
    final categoria = categoriaController.text.trim();

    if (valor != null &&
        valor > 0 &&
        descricao.isNotEmpty &&
        categoria.isNotEmpty) {
      final nova = Transacao(tipo, valor, descricao, categoria);
      setState(() {
        transacoes.add(nova);
        calcularSaldo();
        salvarDados();
      });
      valorController.clear();
      descricaoController.clear();
      categoriaController.clear();
    }
  }

  void calcularSaldo() {
    double total = 0.0;
    for (var t in transacoes) {
      total += t.tipo == 'entrada' ? t.valor : -t.valor;
    }
    saldo = total;
  }

  void excluirTransacao(int index) {
    setState(() {
      transacoes.removeAt(index);
      calcularSaldo();
      salvarDados();
    });
  }

  void atualizarTransacao(int index, Transacao novaTransacao) {
    setState(() {
      transacoes[index] = novaTransacao;
      calcularSaldo();
      salvarDados();
    });
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => TelaLogin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Controle Financeiro - ${widget.usuarioEmail}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Saldo: R\$ ${saldo.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: descricaoController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: categoriaController,
              decoration: InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: valorController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => adicionarTransacao('entrada'),
                    child: Text('Adicionar Receita'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => adicionarTransacao('saida'),
                    child: Text('Adicionar Despesa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CategoriasPage(transacoes: transacoes),
                  ),
                );
              },
              child: Text('Visualizar por Categoria'),
            ),
            Divider(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: transacoes.length,
                itemBuilder: (context, index) {
                  final t = transacoes[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        t.tipo == 'entrada'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: t.tipo == 'entrada' ? Colors.green : Colors.red,
                      ),
                      title: Text(t.descricao),
                      subtitle: Text(
                        'R\$ ${t.valor.toStringAsFixed(2)} • ${t.categoria}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditarTransacaoPage(
                                        transacao: t,
                                        index: index,
                                        onSave: atualizarTransacao,
                                      ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => excluirTransacao(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Transacao {
  final String tipo; // 'entrada' ou 'saida'
  final double valor;
  final String descricao;
  final String categoria;

  Transacao(this.tipo, this.valor, this.descricao, this.categoria);

  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'valor': valor,
    'descricao': descricao,
    'categoria': categoria,
  };

  static Transacao fromJson(Map<String, dynamic> json) => Transacao(
    json['tipo'],
    json['valor'],
    json['descricao'],
    json['categoria'],
  );
}

class CategoriasPage extends StatelessWidget {
  final List<Transacao> transacoes;

  CategoriasPage({required this.transacoes});

  @override
  Widget build(BuildContext context) {
    final categorias = <String, List<Transacao>>{};

    for (var t in transacoes) {
      categorias[t.categoria] = categorias[t.categoria] ?? [];
      categorias[t.categoria]!.add(t);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Despesas por Categoria')),
      body: ListView(
        children:
            categorias.entries.map((entry) {
              final categoria = entry.key;
              final lista = entry.value;
              final total = lista.fold(
                0.0,
                (soma, t) => soma + (t.tipo == 'entrada' ? t.valor : -t.valor),
              );

              return Card(
                child: ListTile(
                  title: Text(categoria),
                  subtitle: Text('Total: R\$ ${total.toStringAsFixed(2)}'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: Text('Detalhes: $categoria'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(
                                children:
                                    lista
                                        .map(
                                          (t) => ListTile(
                                            title: Text(t.descricao),
                                            subtitle: Text(
                                              'R\$ ${t.valor.toStringAsFixed(2)} (${t.tipo})',
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Fechar'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              );
            }).toList(),
      ),
    );
  }
}

class EditarTransacaoPage extends StatefulWidget {
  final Transacao transacao;
  final int index;
  final Function(int, Transacao) onSave;

  EditarTransacaoPage({
    required this.transacao,
    required this.index,
    required this.onSave,
  });

  @override
  _EditarTransacaoPageState createState() => _EditarTransacaoPageState();
}

class _EditarTransacaoPageState extends State<EditarTransacaoPage> {
  late TextEditingController descricaoController;
  late TextEditingController valorController;
  late TextEditingController categoriaController;
  late String tipo;

  @override
  void initState() {
    super.initState();
    tipo = widget.transacao.tipo;
    descricaoController = TextEditingController(
      text: widget.transacao.descricao,
    );
    valorController = TextEditingController(
      text: widget.transacao.valor.toString(),
    );
    categoriaController = TextEditingController(
      text: widget.transacao.categoria,
    );
  }

  void salvarEdicao() {
    final valor = double.tryParse(valorController.text);
    final descricao = descricaoController.text.trim();
    final categoria = categoriaController.text.trim();

    if (valor != null &&
        valor > 0 &&
        descricao.isNotEmpty &&
        categoria.isNotEmpty) {
      final transacaoAtualizada = Transacao(tipo, valor, descricao, categoria);
      widget.onSave(widget.index, transacaoAtualizada);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Transação')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: tipo,
              decoration: InputDecoration(labelText: 'Tipo'),
              items:
                  ['entrada', 'saida'].map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo == 'entrada' ? 'Receita' : 'Despesa'),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => tipo = value);
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: descricaoController,
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: categoriaController,
              decoration: InputDecoration(labelText: 'Categoria'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: valorController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Valor'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: salvarEdicao,
              child: Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
