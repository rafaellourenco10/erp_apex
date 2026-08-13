class Cliente {
  final int idCliente;
  final String nome;
  final String? email;
  final String? telefone;

  const Cliente({
    required this.idCliente,
    required this.nome,
    this.email,
    this.telefone,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['id_cliente'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
    );
  }
}
