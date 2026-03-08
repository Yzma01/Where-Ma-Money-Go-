class Subcategory {
  final String name;
  final String? id;

  Subcategory({required this.name, this.id});

  Map<String, dynamic> toMap() {
    return {'name': name, 'id': id};
  }

  factory Subcategory.fromMap(Map<String, dynamic> map) {
    return Subcategory(name: map['name'], id: map['id']);
  }
}
