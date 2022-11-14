class PostItem {
  final String title;
  final int createTime;
  final int updateTime;
  final String category;

  const PostItem({
    required this.title,
    required this.createTime,
    required this.updateTime,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'createTime': createTime,
      'updateTime': updateTime,
      'category': category,
    };
  }

  factory PostItem.fromJson(Map<String, dynamic> map) {
    return PostItem(
      title: map['title'] as String,
      createTime: map['createTime'] as int,
      updateTime: map['updateTime'] as int,
      category: map['category'] as String,
    );
  }
}