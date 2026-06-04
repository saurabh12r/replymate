import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../models/broker_model.dart';
import '../../models/replymet_user.dart';


class CampaignScreen extends ConsumerStatefulWidget {
  const CampaignScreen({super.key});

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: PageHeader(
                  title: 'Campaigns',
                  subtitle: 'Send push notifications to your users',
                  icon: Icons.campaign_rounded,
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'New Campaign'),
            Tab(text: 'History'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const _NewCampaignTab(),
              const _CampaignHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _NewCampaignTab extends ConsumerStatefulWidget {
  const _NewCampaignTab();

  @override
  ConsumerState<_NewCampaignTab> createState() => _NewCampaignTabState();
}

class _NewCampaignTabState extends ConsumerState<_NewCampaignTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _targetType = 'all'; // all, my_users, expiring_in_2_days, specific_plan, specific_user, specific_broker
  String? _selectedPlanId;
  List<ReplymetUser> _selectedUsers = [];

  Uint8List? _imageBytes;
  String? _imageExtension;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1000,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageExtension = pickedFile.name.split('.').last;
      });
    }
  }

  Future<void> _showUserSelectionDialog(BuildContext context, bool isAdmin) async {
    final List<ReplymetUser>? selectedUsers = await showDialog<List<ReplymetUser>>(
      context: context,
      builder: (context) => _UserSelectionDialog(
        isAdmin: isAdmin,
        initialSelectedUsers: _selectedUsers,
      ),
    );

    if (selectedUsers != null) {
      setState(() {
        _selectedUsers = selectedUsers;
        _selectedPlanId = selectedUsers.map((u) => u.uid).join(',');
      });
    }
  }

  Future<void> _sendCampaign() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetType == 'specific_plan' && _selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_targetType == 'specific_user' && _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_targetType == 'specific_broker' && _selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a broker'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageBytes != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('campaign_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.$_imageExtension');
        await ref.putData(_imageBytes!);
        imageUrl = await ref.getDownloadURL();
      }

      final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
      final result = await functions.httpsCallable('sendCampaignNotification').call({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'imageUrl': imageUrl,
        'targetType': _targetType,
        'planId': _selectedPlanId,
      });

      final data = result.data as Map<String, dynamic>;
      final successCount = data['success'] ?? 0;
      final total = data['total'] ?? 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully sent $successCount out of $total notifications.')),
        );
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _imageBytes = null;
          _targetType = 'all';
          _selectedPlanId = null;
          _selectedUsers = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send campaign: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = user?.isAdmin == true;
    final plansAsync = ref.watch(activePlansStreamProvider);
    final brokersAsync = ref.watch(brokersStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Campaign Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notification Message',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target Audience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _targetType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Filter Users',
                    ),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('All Your Users')),
                      if (isAdmin) ...[
                        const DropdownMenuItem(value: 'my_users', child: Text('My Users (No Broker)')),
                        const DropdownMenuItem(value: 'all_brokers', child: Text('All Broker Users')),
                        const DropdownMenuItem(value: 'specific_broker', child: Text('Specific Broker Users')),
                      ],
                      const DropdownMenuItem(value: 'expiring_in_2_days', child: Text('Expiring in 2 Days')),
                      const DropdownMenuItem(value: 'specific_plan', child: Text('Specific Plan')),
                      const DropdownMenuItem(value: 'specific_user', child: Text('Specific User')),
                    ],
                    onChanged: (v) => setState(() {
                      _targetType = v!;
                      _selectedPlanId = null;
                      _selectedUsers = [];
                    }),
                  ),
                  if (_targetType == 'specific_plan') ...[
                    const SizedBox(height: 16),
                    plansAsync.when(
                      data: (plans) => DropdownButtonFormField<String>(
                        value: _selectedPlanId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Select Plan',
                        ),
                        items: plans.map((p) => DropdownMenuItem(value: p.planId, child: Text(p.name))).toList(),
                        onChanged: (v) => setState(() => _selectedPlanId = v),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error loading plans: $e'),
                    ),
                  ],
                  if (_targetType == 'specific_user') ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _showUserSelectionDialog(context, isAdmin),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedUsers.isNotEmpty ? Icons.people : Icons.person_add_alt_1,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedUsers.isNotEmpty ? 'Selected Users (${_selectedUsers.length})' : 'Select Target Users',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  if (_selectedUsers.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: _selectedUsers.map((user) {
                                        return InputChip(
                                          label: Text(
                                            user.name.isNotEmpty ? '${user.name} (${user.phone})' : user.phone,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedUsers.removeWhere((u) => u.uid == user.uid);
                                              _selectedPlanId = _selectedUsers.isEmpty
                                                  ? null
                                                  : _selectedUsers.map((u) => u.uid).join(',');
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_targetType == 'specific_broker') ...[
                    const SizedBox(height: 16),
                    brokersAsync.when(
                      data: (brokers) => DropdownButtonFormField<String>(
                        value: _selectedPlanId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Select Broker',
                        ),
                        items: brokers.map((b) => DropdownMenuItem(value: b.brokerId, child: Text(b.name))).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedPlanId = v;
                          });
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error loading brokers: $e'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Attached Image (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_imageBytes != null) ...[
                    Stack(
                      children: [
                        Image.memory(_imageBytes!, height: 150, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => _imageBytes = null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Image'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendCampaign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send Campaign Notification', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignHistoryTab extends ConsumerWidget {
  const _CampaignHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = user?.isAdmin == true;
    final asyncCampaigns = isAdmin ? ref.watch(campaignsStreamProvider) : ref.watch(brokerCampaignsProvider);

    return asyncCampaigns.when(
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return const Center(child: Text('No campaigns sent yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final campaign = campaigns[index];
            return AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(campaign.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(AppUtils.formatDate(campaign.createdAt ?? DateTime.now())),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(campaign.message),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(label: Text('Filter: ${campaign.targetType}'), labelStyle: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('Sent: ${campaign.successCount} / ${campaign.totalTargeted}'),
                        backgroundColor: AppTheme.successColor.withOpacity(0.1),
                        labelStyle: const TextStyle(color: AppTheme.successColor, fontSize: 12),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        Chip(label: Text('By: ${campaign.senderName}'), labelStyle: const TextStyle(fontSize: 12)),
                      ]
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _UserSelectionDialog extends ConsumerStatefulWidget {
  final bool isAdmin;
  final List<ReplymetUser> initialSelectedUsers;
  const _UserSelectionDialog({
    required this.isAdmin,
    required this.initialSelectedUsers,
  });

  @override
  ConsumerState<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends ConsumerState<_UserSelectionDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'my_users'; // Initial filter: Only My Users
  String? _selectedFilterBrokerId;
  final List<ReplymetUser> _tempSelectedUsers = [];

  @override
  void initState() {
    super.initState();
    _tempSelectedUsers.addAll(widget.initialSelectedUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = widget.isAdmin
        ? ref.watch(allUsersStreamProvider)
        : ref.watch(brokerUsersProvider);

    final brokersAsync = widget.isAdmin
        ? ref.watch(brokersStreamProvider)
        : const AsyncValue<List<BrokerModel>>.data([]);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 600 : double.infinity,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Target Users',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
            if (widget.isAdmin) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter Users by Association',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'my_users', child: Text('Only My Users (No Broker)')),
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(value: 'by_broker', child: Text('Filter by Broker')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedFilter = val!;
                    if (_selectedFilter != 'by_broker') {
                      _selectedFilterBrokerId = null;
                    }
                  });
                },
              ),
              if (_selectedFilter == 'by_broker') ...[
                const SizedBox(height: 12),
                brokersAsync.when(
                  data: (brokers) {
                    if (_selectedFilterBrokerId == null && brokers.isNotEmpty) {
                      _selectedFilterBrokerId = brokers.first.brokerId;
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedFilterBrokerId,
                      decoration: const InputDecoration(
                        labelText: 'Select Broker',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: brokers
                          .map((b) => DropdownMenuItem(
                                value: b.brokerId,
                                child: Text(b.name),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedFilterBrokerId = val),
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, _) => Text('Error loading brokers: $e', style: const TextStyle(color: Colors.red)),
                ),
              ],
            ],
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  final filtered = users.where((u) {
                    if (widget.isAdmin) {
                      if (_selectedFilter == 'my_users') {
                        if (u.brokerId != null && u.brokerId!.isNotEmpty) {
                          return false;
                        }
                      } else if (_selectedFilter == 'by_broker') {
                        if (u.brokerId != _selectedFilterBrokerId) {
                          return false;
                        }
                      }
                    }

                    if (_searchQuery.isNotEmpty) {
                      final nameMatches = u.name.toLowerCase().contains(_searchQuery);
                      final phoneMatches = u.phone.contains(_searchQuery);
                      if (!nameMatches && !phoneMatches) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No users found matching the filter.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final isSelected = _tempSelectedUsers.any((u) => u.uid == user.uid);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              if (!_tempSelectedUsers.any((u) => u.uid == user.uid)) {
                                _tempSelectedUsers.add(user);
                              }
                            } else {
                              _tempSelectedUsers.removeWhere((u) => u.uid == user.uid);
                            }
                          });
                        },
                        title: Text(
                          user.name.isNotEmpty ? user.name : 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          user.phone.isNotEmpty ? user.phone : 'No Phone Number',
                          style: const TextStyle(letterSpacing: 0.5),
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppTheme.primaryColor),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error loading users: $e', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _tempSelectedUsers),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Select (${_tempSelectedUsers.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

