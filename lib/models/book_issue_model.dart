class BookIssueModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String userId;
  final String userName;
  final String? userGroup;
  final String? userStage;
  final String issueDate; // YYYY-MM-DD
  final String dueDate;   // YYYY-MM-DD
  final String? returnDate; // YYYY-MM-DD or null
  final String status; // 'ISSUED', 'RETURNED', 'OVERDUE'
  final String? notes;

  BookIssueModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.userId,
    required this.userName,
    this.userGroup,
    this.userStage,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
    this.notes,
  });

  bool get isReturned => status == 'RETURNED' || returnDate != null;

  bool get isOverdue {
    if (isReturned) return false;
    final due = DateTime.tryParse(dueDate);
    if (due == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(due);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'userId': userId,
      'userName': userName,
      'userGroup': userGroup,
      'userStage': userStage,
      'issueDate': issueDate,
      'dueDate': dueDate,
      'returnDate': returnDate,
      'status': status,
      'notes': notes,
    };
  }

  factory BookIssueModel.fromMap(Map<String, dynamic> map) {
    return BookIssueModel(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      bookTitle: map['bookTitle'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userGroup: map['userGroup'] as String?,
      userStage: map['userStage'] as String?,
      issueDate: map['issueDate'] as String,
      dueDate: map['dueDate'] as String,
      returnDate: map['returnDate'] as String?,
      status: map['status'] as String? ?? 'ISSUED',
      notes: map['notes'] as String?,
    );
  }

  BookIssueModel copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? userId,
    String? userName,
    String? userGroup,
    String? userStage,
    String? issueDate,
    String? dueDate,
    String? returnDate,
    String? status,
    String? notes,
  }) {
    return BookIssueModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userGroup: userGroup ?? this.userGroup,
      userStage: userStage ?? this.userStage,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
