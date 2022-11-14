class CategoryItem {
  final String name;
  final int postCount;



  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'postCount': postCount,
    };
  }

  factory CategoryItem.fromJson(Map<String, dynamic> map) {
    return CategoryItem(
      name: map['name'] as String,
      postCount: map['postCount'] as int,
    );
  }

  const CategoryItem({
    required this.name,
    required this.postCount,
  });
}