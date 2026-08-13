class Produto {
  final int idProduto;
  final String nome;
  final String? descricao;
  final double preco;
  final int estoque;

  const Produto({
    required this.idProduto,
    required this.nome,
    this.descricao,
    required this.preco,
    required this.estoque,
  });

  bool get estoqueBaixo => estoque <= 20;

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      idProduto: json['id_produto'] as int,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      preco: (json['preco'] as num).toDouble(),
      estoque: json['estoque'] as int,
    );
  }
}
