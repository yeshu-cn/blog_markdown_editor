class PostDetail {
  final String title;
  final int createTime;
  final int updateTime;
  final String category;
  final String content;
  bool hasImage;
  List<String> imagePathList = [];

  PostDetail({
    required this.title,
    required this.createTime,
    required this.updateTime,
    required this.category,
    required this.content,
    this.hasImage = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'createTime': createTime,
      'updateTime': updateTime,
      'category': category,
      'content': content,
    };
  }

  factory PostDetail.fromJson(Map<String, dynamic> map) {
    return PostDetail(
      title: map['title'] as String,
      createTime: map['createTime'] as int,
      updateTime: map['updateTime'] as int,
      category: map['category'] as String,
      content: map['content'] as String,
    );
  }
}