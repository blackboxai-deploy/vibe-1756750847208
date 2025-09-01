import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nurse_system/services/excel_service.dart';

class UserDataSeeder extends StatefulWidget {
  const UserDataSeeder({Key? key}) : super(key: key);

  @override
  _UserDataSeederState createState() => _UserDataSeederState();
}

class _UserDataSeederState extends State<UserDataSeeder>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _idCardController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ncdsController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _searchController = TextEditingController();

  final _villageController = TextEditingController();
  final _subDistrictController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingUserId;
  String _selectedGender = 'male';
  String _searchQuery = '';
  String _filterNCDs = 'all';
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  String _selectedTechLevel = 'beginner';
  String _filterTechLevel = 'all';
  String _filterArea = 'all';

  final Map<String, List<String>> _areas = {
    'เมืองเชียงราย': ['ท่าสาย', 'รอบเวียง', 'วัดเกต', 'หลวง', 'ผาตัก'],
    'แม่จัน': ['แม่จัน', 'ป่าก่อดำ', 'จันจวา', 'ห้วยโศก', 'ไชยพฤกษ์'],
    'แม่สาย': ['ไวอาง', 'โป่งผา', 'ศรีเมืองใหม่', 'หัวดง', 'เกาะช้าง'],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _idCardController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _ncdsController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _searchController.dispose();

    _villageController.dispose();
    _subDistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  double _calculateBMI(double weight, double height) {
    if (weight <= 0 || height <= 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  String _getBMIStatus(double bmi) {
    if (bmi < 18.5) return 'ผอม';
    if (bmi < 25) return 'ปกติ';
    if (bmi < 30) return 'อ้วน';
    return 'อ้วนมาก';
  }

  void _clearForm() {
    _idCardController.clear();
    _nameController.clear();
    _addressController.clear();
    _phoneController.clear();
    _ncdsController.clear();
    _ageController.clear();
    _weightController.clear();
    _heightController.clear();

    _villageController.clear();
    _subDistrictController.clear();
    _districtController.clear();
    _provinceController.clear();
    setState(() {
      _selectedGender = 'male';
      _selectedTechLevel = 'beginner';
      _isEditing = false;
      _editingUserId = null;
    });
  }

  void _loadUserForEdit(String userId, Map<String, dynamic> userData) {
    setState(() {
      _isEditing = true;
      _editingUserId = userId;
      _idCardController.text = userData['idCard'] ?? '';
      _nameController.text = userData['name'] ?? '';
      _addressController.text = userData['address'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _ncdsController.text = userData['ncds'] ?? '';
      _ageController.text = userData['age']?.toString() ?? '';
      _weightController.text = userData['weight']?.toString() ?? '';
      _heightController.text = userData['height']?.toString() ?? '';
      _selectedGender = userData['gender'] ?? 'male';

      _villageController.text = userData['village'] ?? '';
      _subDistrictController.text = userData['subDistrict'] ?? '';
      _districtController.text = userData['district'] ?? '';
      _provinceController.text = userData['province'] ?? '';
      _selectedTechLevel = userData['techLevel'] ?? 'beginner';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(colorScheme),
              Expanded(
                child: isSmallScreen
                    ? SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              height: 800,
                              child: _buildUserForm(colorScheme),
                            ),
                            Container(
                              height: 800,
                              child: _buildUsersTable(colorScheme),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildUserForm(colorScheme),
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildUsersTable(colorScheme),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Hero(
            tag: 'seeder_icon',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ระบบจัดการข้อมูลผู้ใช้งาน',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'เพิ่ม แก้ไข และติดตามข้อมูลผู้ใช้โรคไม่ติดต่อเรื้อรัง',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          // ส่วนปุ่ม Download Template ด้านขวาบน
          _buildDownloadTemplateButtons(),
        ],
      ),
    );
  }

  // Widget สำหรับปุ่ม Download Template
  Widget _buildDownloadTemplateButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ปุ่ม Download ข้อมูลปัจจุบัน
        Tooltip(
          message: 'ดาวน์โหลดข้อมูลผู้ใช้ปัจจุบันทั้งหมด',
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _downloadCurrentDataTemplate,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ดาวน์โหลดข้อมูล',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ปุ่ม Download Template ว่าง
        Tooltip(
          message: 'ดาวน์โหลด Template ว่างสำหรับกรอกข้อมูลใหม่',
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _downloadEmptyTemplate,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.file_download_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Template ว่าง',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ปุ่ม Menu สำหรับตัวเลือกเพิ่มเติม
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'download_current',
              child: Row(
                children: [
                  Icon(Icons.download, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 12),
                  Text('ดาวน์โหลดข้อมูลปัจจุบัน'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'download_empty',
              child: Row(
                children: [
                  Icon(Icons.file_download, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Text('ดาวน์โหลด Template ว่าง'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'import_excel',
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Text('Import จาก Excel'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'download_current':
                _downloadCurrentDataTemplate();
                break;
              case 'download_empty':
                _downloadEmptyTemplate();
                break;
              case 'import_excel':
                _importExcel();
                break;
            }
          },
        ),
      ],
    );
  }

  // ฟังก์ชันสำหรับดาวน์โหลดข้อมูลปัจจุบัน
  Future<void> _downloadCurrentDataTemplate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ExcelImportService.downloadTemplate(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? const Color(0xFF10B981) : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        
        if (result.success) {
          _showDownloadSuccessDialog(
            'ดาวน์โหลดข้อมูลสำเร็จ',
            'ได้ดาวน์โหลดข้อมูลผู้ใช้ ${result.totalRecords} รายการแล้ว\n\nไฟล์ถูกบันทึกไว้ที่: ${result.filePath}',
            result.filePath,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ฟังก์ชันสำหรับดาวน์โหลด Template ว่าง
  Future<void> _downloadEmptyTemplate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ExcelImportService.downloadEmptyTemplate(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.blue : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        
        if (result.success) {
          _showDownloadSuccessDialog(
            'ดาวน์โหลด Template สำเร็จ',
            'ได้ดาวน์โหลด Template ว่างพร้อมตัวอย่างข้อมูลแล้ว\n\nไฟล์ถูกบันทึกไว้ที่: ${result.filePath}',
            result.filePath,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Dialog แสดงความสำเร็จในการดาวน์โหลด
  void _showDownloadSuccessDialog(String title, String message, String? filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (filePath != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filePath,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Widget _buildTechLevelDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            _selectedTechLevel == 'beginner'
                ? Icons.phonelink_off_rounded
                : _selectedTechLevel == 'intermediate'
                    ? Icons.smartphone_rounded
                    : Icons.computer_rounded,
            color: _selectedTechLevel == 'beginner'
                ? Colors.red
                : _selectedTechLevel == 'intermediate'
                    ? Colors.orange
                    : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTechLevel,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'beginner',
                      child: Text('ไม่เก่งเทคโนโลยี (ต้องดูแลพิเศษ)')),
                  DropdownMenuItem(
                      value: 'intermediate',
                      child: Text('เก่งปานกลาง (ใช้โทรศัพท์ได้)')),
                  DropdownMenuItem(
                      value: 'advanced',
                      child: Text('เก่งเทคโนโลยี (ใช้แอปได้)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTechLevel = value ?? 'beginner';
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFF8FAFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.5,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isEditing
                            ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                            : [
                                const Color(0xFF10B981),
                                const Color(0xFF059669)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                        _isEditing
                            ? Icons.edit_rounded
                            : Icons.person_add_rounded,
                        color: Colors.white,
                        size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isEditing ? 'แก้ไขข้อมูลผู้ใช้' : 'เพิ่มผู้ใช้ใหม่',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isEditing)
                  TextButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.clear),
                    label: const Text('ยกเลิก'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _idCardController,
                            label: 'เลขบัตรประจำตัวประชาชน',
                            icon: Icons.credit_card_rounded,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'กรุณาใส่เลขบัตรประจำตัวประชาชน';
                              }
                              if (value!.length != 13) {
                                return 'เลขบัตรประจำตัวประชาชนต้องมี 13 หลัก';
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(13),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _ageController,
                            label: 'อายุ (ปี)',
                            icon: Icons.cake_rounded,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'กรุณาใส่อายุ';
                              }
                              final age = int.tryParse(value!);
                              if (age == null || age <= 0 || age > 150) {
                                return 'กรุณาใส่อายุที่ถูกต้อง';
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _nameController,
                            label: 'ชื่อ-นามสกุล',
                            icon: Icons.person_rounded,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'กรุณาใส่ชื่อ-นามสกุล';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGenderDropdown(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _weightController,
                            label: 'น้ำหนัก (กก.)',
                            icon: Icons.monitor_weight_rounded,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'กรุณาใส่น้ำหนัก';
                              }
                              final weight = double.tryParse(value!);
                              if (weight == null ||
                                  weight <= 0 ||
                                  weight > 500) {
                                return 'กรุณาใส่น้ำหนักที่ถูกต้อง';
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _heightController,
                            label: 'ส่วนสูง (ซม.)',
                            icon: Icons.height_rounded,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'กรุณาใส่ส่วนสูง';
                              }
                              final height = double.tryParse(value!);
                              if (height == null ||
                                  height <= 0 ||
                                  height > 300) {
                                return 'กรุณาใส่ส่วนสูงที่ถูกต้อง';
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _phoneController,
                      label: 'เบอร์มือถือ',
                      icon: Icons.phone_rounded,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'กรุณาใส่เบอร์มือถือ';
                        }
                        if (value!.length != 10) {
                          return 'เบอร์มือถือต้องมี 10 หลัก';
                        }
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _addressController,
                      label: 'ที่อยู่',
                      icon: Icons.location_on_rounded,
                      maxLines: 3,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'กรุณาใส่ที่อยู่';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Color(0xFF10B981)),
                              SizedBox(width: 8),
                              Text(
                                'ข้อมูลพื้นที่',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _villageController,
                                  label: 'หมู่บ้าน/ชุมชน',
                                  icon: Icons.home_work_rounded,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'กรุณาใส่หมู่บ้าน/ชุมชน';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _subDistrictController,
                                  label: 'ตำบล',
                                  icon: Icons.location_city_rounded,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'กรุณาใส่ตำบล';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _districtController,
                                  label: 'อำเภอ',
                                  icon: Icons.domain_rounded,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'กรุณาใส่อำเภอ';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _provinceController,
                                  label: 'จังหวัด',
                                  icon: Icons.map_rounded,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'กรุณาใส่จังหวัด';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.smartphone, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'ความเก่งด้านเทคโนโลยี',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '* สำหรับจัดกลุ่มการดูแลและระบุความต้องการช่วยเหลือพิเศษ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTechLevelDropdown(),
                          if (_selectedTechLevel == 'beginner') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.priority_high,
                                      color: Colors.red, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ต้องการการดูแลพิเศษจาก อสม. อาจต้องติดตามด้วยการเยี่ยมบ้าน',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _ncdsController,
                      label: 'โรคประจำตัว NCDs',
                      icon: Icons.medical_information_rounded,
                      maxLines: 2,
                      required: false,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (_isEditing ? _updateUser : _addUser),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEditing
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_isEditing
                                          ? Icons.update_rounded
                                          : Icons.add_rounded),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _isEditing
                                              ? 'อัปเดตข้อมูล'
                                              : 'เพิ่มผู้ใช้',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _importExcel,
                            icon: const Icon(Icons.upload_file, size: 20),
                            label: const Text(
                              'Import Excel',
                              style: TextStyle(fontSize: 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFF10B981), width: 2),
                              foregroundColor: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGender,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('ชาย')),
                  DropdownMenuItem(value: 'female', child: Text('หญิง')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value ?? 'male';
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildUsersTable(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFF8FAFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.table_chart_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'รายการผู้ใช้',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSearchAndFilter(),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildFilteredQuery(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('ไม่มีข้อมูลผู้ใช้'),
                  );
                }

                final users = snapshot.data!.docs;
                final filteredUsers = _filterUsers(users);
                final totalPages =
                    (filteredUsers.length / _itemsPerPage).ceil();
                final startIndex = _currentPage * _itemsPerPage;
                final endIndex =
                    (startIndex + _itemsPerPage).clamp(0, filteredUsers.length);
                final paginatedUsers =
                    filteredUsers.sublist(startIndex, endIndex);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: paginatedUsers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = paginatedUsers[index];
                          final data = user.data() as Map<String, dynamic>;

                          return _buildUserCard(user, data, colorScheme);
                        },
                      ),
                    ),
                    if (totalPages > 1) _buildPagination(totalPages),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                    _currentPage = 0;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อ, เลขบัตร, หรือเบอร์โทร...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF10B981)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  color: Colors.white,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterTechLevel,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('ทุกระดับ')),
                      DropdownMenuItem(
                          value: 'beginner', child: Text('ไม่เก่งเทคโนโลยี')),
                      DropdownMenuItem(
                          value: 'intermediate', child: Text('เก่งปานกลาง')),
                      DropdownMenuItem(
                          value: 'advanced', child: Text('เก่งเทคโนโลยี')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterTechLevel = value ?? 'all';
                        _currentPage = 0;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  color: Colors.white,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterArea,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                          value: 'all', child: Text('ทุกพื้นที่')),
                      ..._areas.keys.map((district) => DropdownMenuItem(
                          value: district, child: Text(district))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterArea = value ?? 'all';
                        _currentPage = 0;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _buildFilteredQuery() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    return users.where((user) {
      final data = user.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final idCard = (data['idCard'] ?? '').toString();
      final phone = (data['phone'] ?? '').toString();
      final ncds = (data['ncds'] ?? '').toString();
      final techLevel = (data['techLevel'] ?? '').toString();
      final district = (data['district'] ?? '').toString();

      bool matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          idCard.contains(_searchQuery) ||
          phone.contains(_searchQuery);

      bool matchesNCDs = true;
      if (_filterNCDs != 'all') {
        switch (_filterNCDs) {
          case 'diabetes':
            matchesNCDs = ncds.contains('เบาหวาน') || ncds.contains('diabetes');
            break;
          case 'hypertension':
            matchesNCDs = ncds.contains('ความดันโลหิตสูง') ||
                ncds.contains('ความดัน') ||
                ncds.contains('hypertension');
            break;
          case 'heart_disease':
            matchesNCDs = ncds.contains('โรคหัวใจและหลอดเลือด') ||
                ncds.contains('หัวใจและหลอดเลือด') ||
                ncds.contains('heart');
            break;
          case 'stroke':
            matchesNCDs = ncds.contains('โรคหลอดเลือดสมอง') ||
                ncds.contains('stroke') ||
                ncds.contains('หลอดเลือดสมอง');
            break;
          case 'kidney_disease':
            matchesNCDs = ncds.contains('โรคไต') ||
                ncds.contains('ไต') ||
                ncds.contains('kidney');
            break;
          case 'cancer':
            matchesNCDs = ncds.contains('มะเร็ง') || ncds.contains('cancer');
            break;
          case 'copd':
            matchesNCDs = ncds.contains('ปอดอุดกั้นเรื้อรัง') ||
                ncds.contains('copd') ||
                ncds.contains('ปอด');
            break;
          case 'obesity':
            matchesNCDs = ncds.contains('โรคอ้วน') ||
                ncds.contains('obesity') ||
                ncds.contains('อ้วน');
            break;
          case 'hyperlipidemia':
            matchesNCDs = ncds.contains('โรคไขมันในเลือดสูง') ||
                ncds.contains('hyperlipidemia') ||
                ncds.contains('ไขมันในเลือดสูง');
            break;
          case 'gout':
            matchesNCDs = ncds.contains('โรคเก๊าต์') ||
                ncds.contains('gout') ||
                ncds.contains('เก๊าต์');
            break;
          case 'asthma':
            matchesNCDs = ncds.contains('โรคหอบหืด') ||
                ncds.contains('asthma') ||
                ncds.contains('หอบหืด');
            break;
          case 'liver_disease':
            matchesNCDs = ncds.contains('โรคตับ') ||
                ncds.contains('liver') ||
                ncds.contains('ตับ');
            break;
          default:
            matchesNCDs = true;
        }
      }

      bool matchesTechLevel =
          _filterTechLevel == 'all' || techLevel == _filterTechLevel;

      bool matchesArea = _filterArea == 'all' || district == _filterArea;

      return matchesSearch && matchesNCDs && matchesTechLevel && matchesArea;
    }).toList();
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${_currentPage + 1} / $totalPages'),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    QueryDocumentSnapshot userDoc,
    Map<String, dynamic> data,
    ColorScheme colorScheme,
  ) {
    final name = data['name'] ?? 'ไม่มีชื่อ';
    final idCard = data['idCard'] ?? 'ไม่มีข้อมูล';
    final phone = data['phone'] ?? 'ไม่มีข้อมูล';
    final address = data['address'] ?? 'ไม่มีข้อมูล';
    final ncds = data['ncds'] ?? '';
    final age = data['age']?.toString() ?? '-';
    final gender = data['gender'] == 'male' ? 'ชาย' : 'หญิง';
    final weight = data['weight']?.toDouble() ?? 0;
    final height = data['height']?.toDouble() ?? 0;
    final hasNCDs = ncds.isNotEmpty;
    final village = data['village'] ?? '';
    final subDistrict = data['subDistrict'] ?? '';
    final district = data['district'] ?? '';
    final province = data['province'] ?? '';
    final techLevel = data['techLevel'] ?? 'beginner';

    double bmi = 0;
    String bmiStatus = '-';
    if (weight > 0 && height > 0) {
      bmi = _calculateBMI(weight, height);
      bmiStatus = _getBMIStatus(bmi);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: techLevel == 'beginner'
                ? Colors.red.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      data['gender'] == 'male' ? Icons.male : Icons.female,
                      color:
                          data['gender'] == 'male' ? Colors.blue : Colors.pink,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTechLevelColor(techLevel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _getTechLevelColor(techLevel).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTechLevelIcon(techLevel),
                      color: _getTechLevelColor(techLevel),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTechLevelText(techLevel),
                      style: TextStyle(
                        color: _getTechLevelColor(techLevel),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        color: Color(0xFFF59E0B)),
                    onPressed: () => _loadUserForEdit(userDoc.id, data),
                    tooltip: 'แก้ไข',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                    onPressed: () => _deleteUser(userDoc.id),
                    tooltip: 'ลบ',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('บัตรประชาชน: $idCard',
                        overflow: TextOverflow.ellipsis),
                    Text('เบอร์: $phone', overflow: TextOverflow.ellipsis),
                    Text('อายุ: $age ปี ($gender)',
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (weight > 0 && height > 0)
                      Text(
                          'น้ำหนัก/ส่วนสูง: ${weight.toStringAsFixed(1)}/${height.toStringAsFixed(1)}'),
                    if (bmi > 0)
                      Text(
                        'BMI: ${bmi.toStringAsFixed(1)} ($bmiStatus)',
                        style: TextStyle(
                          color: bmi < 18.5 || bmi >= 25
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('ที่อยู่: $address',
              maxLines: 2, overflow: TextOverflow.ellipsis),
          if (hasNCDs) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.medical_information,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'โรค NCDs: $ncds',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (village.isNotEmpty || district.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'พื้นที่: $village, $subDistrict, $district, $province',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF10B981), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (techLevel == 'beginner') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.priority_high, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'ต้องการการดูแลพิเศษจาก อสม. - แนะนำการเยี่ยมบ้าน',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _importExcel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ExcelImportService.importExcelFile(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? const Color(0xFF10B981) : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkDuplicateData(String idCard, String phone,
      [String? excludeUserId]) async {
    try {
      final idCardQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('idCard', isEqualTo: idCard)
          .get();

      for (var doc in idCardQuery.docs) {
        if (excludeUserId == null || doc.id != excludeUserId) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('เลขบัตรประจำตัวประชาชนนี้ถูกใช้งานแล้ว'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return true;
        }
      }

      final phoneQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();

      for (var doc in phoneQuery.docs) {
        if (excludeUserId == null || doc.id != excludeUserId) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('เบอร์โทรศัพท์นี้ถูกใช้งานแล้ว'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking duplicate data: $e');
      return false;
    }
  }

  String _getTechLevelText(String techLevel) {
    switch (techLevel) {
      case 'beginner':
        return 'ไม่เก่งเทคโนโลยี';
      case 'intermediate':
        return 'เก่งปานกลาง';
      case 'advanced':
        return 'เก่งเทคโนโลยี';
      default:
        return 'ไม่ระบุ';
    }
  }

  Color _getTechLevelColor(String techLevel) {
    switch (techLevel) {
      case 'beginner':
        return Colors.red;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTechLevelIcon(String techLevel) {
    switch (techLevel) {
      case 'beginner':
        return Icons.phonelink_off_rounded;
      case 'intermediate':
        return Icons.smartphone_rounded;
      case 'advanced':
        return Icons.computer_rounded;
      default:
        return Icons.help;
    }
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final idCard = _idCardController.text.trim();
      final phone = _phoneController.text.trim();
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();
      final ncds = _ncdsController.text.trim();
      final age = int.parse(_ageController.text.trim());
      final weight = double.parse(_weightController.text.trim());
      final height = double.parse(_heightController.text.trim());

      final hasDuplicate = await _checkDuplicateData(idCard, phone);

      if (hasDuplicate) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String mockEmail = "$phone@phone.local";
      String mockPassword = "phone_$phone";

      UserCredential? credential;
      try {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: mockEmail,
          password: mockPassword,
        );
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          try {
            credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: mockEmail,
              password: mockPassword,
            );
          } catch (loginError) {
            throw Exception(
                'ไม่สามารถสร้างหรือเข้าสู่ระบบได้: ${loginError.toString()}');
          }
        } else {
          throw e;
        }
      }

      if (credential.user == null) {
        throw Exception('ไม่สามารถสร้าง Firebase Auth account ได้');
      }

      await credential.user!.updateDisplayName(name);

      final bmi = _calculateBMI(weight, height);

      final userData = {
        'uid': credential.user!.uid,
        'idCard': idCard,
        'name': name,
        'address': address,
        'phone': phone,
        'ncds': ncds,
        'age': age,
        'gender': _selectedGender,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'email': mockEmail,

        'village': _villageController.text.trim(),
        'subDistrict': _subDistrictController.text.trim(),
        'district': _districtController.text.trim(),
        'province': _provinceController.text.trim(),
        'techLevel': _selectedTechLevel,
        'needsSpecialCare': _selectedTechLevel == 'beginner',

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);

      await FirebaseAuth.instance.signOut();

      _clearForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เพิ่มผู้ใช้สำเร็จ พร้อม Firebase Auth account'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final idCard = _idCardController.text.trim();
      final phone = _phoneController.text.trim();
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();
      final ncds = _ncdsController.text.trim();
      final age = int.parse(_ageController.text.trim());
      final weight = double.parse(_weightController.text.trim());
      final height = double.parse(_heightController.text.trim());

      final hasDuplicate =
          await _checkDuplicateData(idCard, phone, _editingUserId);

      if (hasDuplicate) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final bmi = _calculateBMI(weight, height);

      final userData = {
        'idCard': idCard,
        'name': name,
        'address': address,
        'phone': phone,
        'ncds': ncds,
        'age': age,
        'gender': _selectedGender,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_editingUserId)
          .update(userData);

      _clearForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตข้อมูลผู้ใช้สำเร็จ'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text(
            'คุณต้องการลบผู้ใช้นี้หรือไม่?\n\nข้อมูลที่ลบแล้วจะไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .delete();

        if (_editingUserId == docId) {
          _clearForm();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบผู้ใช้สำเร็จ'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}