class Invoice {
  final String accessKey;
  final String date;
  final String sequential;
  final String issuerName;
  final String issuerRuc;
  final double total;
  final String category;
  final String xmlContent;
  final List<InvoiceDetail> details;

  // New fields
  final String environment;
  final String emissionType;
  final String accountingObligation;
  final String matrixAddress;
  final String? establishmentAddress;
  final String customerName;
  final String customerRuc;
  final String customerAddress;
  final String? remissionGuide;
  final double subtotal;
  final double totalDiscount;
  final double iva;
  final double tip;
  final Map<String, String> additionalInfo;
  final List<Payment> payments;

  Invoice({
    required this.accessKey,
    required this.date,
    required this.sequential,
    required this.issuerName,
    required this.issuerRuc,
    required this.total,
    this.category = '',
    required this.xmlContent,
    this.details = const [],
    this.environment = '',
    this.emissionType = '',
    this.accountingObligation = '',
    this.matrixAddress = '',
    this.establishmentAddress,
    this.customerName = '',
    this.customerRuc = '',
    this.customerAddress = '',
    this.remissionGuide,
    this.subtotal = 0.0,
    this.totalDiscount = 0.0,
    this.iva = 0.0,
    this.tip = 0.0,
    this.additionalInfo = const {},
    this.payments = const [],
  });

  Invoice copyWith({
    String? accessKey,
    String? date,
    String? sequential,
    String? issuerName,
    String? issuerRuc,
    double? total,
    String? category,
    String? xmlContent,
    List<InvoiceDetail>? details,
    String? environment,
    String? emissionType,
    String? accountingObligation,
    String? matrixAddress,
    String? establishmentAddress,
    String? customerName,
    String? customerRuc,
    String? customerAddress,
    String? remissionGuide,
    double? subtotal,
    double? totalDiscount,
    double? iva,
    double? tip,
    Map<String, String>? additionalInfo,
    List<Payment>? payments,
  }) {
    return Invoice(
      accessKey: accessKey ?? this.accessKey,
      date: date ?? this.date,
      sequential: sequential ?? this.sequential,
      issuerName: issuerName ?? this.issuerName,
      issuerRuc: issuerRuc ?? this.issuerRuc,
      total: total ?? this.total,
      category: category ?? this.category,
      xmlContent: xmlContent ?? this.xmlContent,
      details: details ?? this.details,
      environment: environment ?? this.environment,
      emissionType: emissionType ?? this.emissionType,
      accountingObligation: accountingObligation ?? this.accountingObligation,
      matrixAddress: matrixAddress ?? this.matrixAddress,
      establishmentAddress: establishmentAddress ?? this.establishmentAddress,
      customerName: customerName ?? this.customerName,
      customerRuc: customerRuc ?? this.customerRuc,
      customerAddress: customerAddress ?? this.customerAddress,
      remissionGuide: remissionGuide ?? this.remissionGuide,
      subtotal: subtotal ?? this.subtotal,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      iva: iva ?? this.iva,
      tip: tip ?? this.tip,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      payments: payments ?? this.payments,
    );
  }
}

class InvoiceDetail {
  final String mainCode;
  final String? auxCode;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double totalPrice;

  InvoiceDetail({
    required this.mainCode,
    this.auxCode,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.totalPrice,
  });
}

class Payment {
  final String method;
  final double total;
  final String timeUnit;
  final double term;

  Payment({
    required this.method,
    required this.total,
    this.timeUnit = '',
    this.term = 0.0,
  });
}
