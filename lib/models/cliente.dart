class Cliente {
  final int idCliente;
  final String nome;
  final String? email;
  final String? telefone;
  final String? cpfCnpj;
  final String? endereco;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? uf;
  final String? cep;

  const Cliente({
    required this.idCliente,
    required this.nome,
    this.email,
    this.telefone,
    this.cpfCnpj,
    this.endereco,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.uf,
    this.cep,
  });

  /// Address formatted for display, e.g. "Rua X, 123 - Bairro, Cidade/UF".
  /// Returns null if [endereco] itself is missing (partial data still shown).
  String? get enderecoCompleto {
    if (endereco == null || endereco!.isEmpty) return null;
    final partes = <String>[endereco!];
    if (numero != null && numero!.isNotEmpty) partes.add(numero!);
    var linha = partes.join(', ');
    if (bairro != null && bairro!.isNotEmpty) linha += ' - $bairro';
    if (cidade != null && cidade!.isNotEmpty) {
      linha += ', $cidade';
      if (uf != null && uf!.isNotEmpty) linha += '/$uf';
    }
    return linha;
  }

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['id_cliente'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      cpfCnpj: json['cpf_cnpj'] as String?,
      endereco: json['endereco'] as String?,
      numero: json['numero'] as String?,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String?,
      cidade: json['cidade'] as String?,
      uf: json['uf'] as String?,
      cep: json['cep'] as String?,
    );
  }
}
