import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _segmentedValue = 1;
  bool _sheetOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScreenHeader(
                    title: 'Component Gallery',
                    subtitle: 'Design System',
                    right: TnButton(
                      size: ButtonSize.sm,
                      variant: ButtonVariant.ghost,
                      child: const Text('Back'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection('Buttons', [
                    TnButton(child: const Text('Primary'), onPressed: () {}),
                    const SizedBox(height: 8),
                    TnButton(
                      variant: ButtonVariant.saffron,
                      child: const Text('Saffron'),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 8),
                    TnButton(
                      variant: ButtonVariant.soft,
                      child: const Text('Soft'),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 8),
                    TnButton(
                      variant: ButtonVariant.ghost,
                      child: const Text('Ghost'),
                      onPressed: () {},
                    ),
                  ]),
                  _buildSection('Badges', [
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StateBadge(state: DaretState.apayer),
                        StateBadge(state: DaretState.attente),
                        StateBadge(state: DaretState.confirme),
                        StateBadge(state: DaretState.retard),
                        StateBadge(state: DaretState.recipient),
                      ],
                    ),
                  ]),
                  _buildSection('Avatars', [
                    Row(
                      children: [
                        const Avatar(data: AvatarData(initials: 'AM')),
                        const SizedBox(width: 16),
                        AvatarStack(
                          avatars: List.generate(
                            6,
                            (i) => AvatarData(
                              initials: r'X$i',
                              bgColor: [
                                TantinColors.majorelle,
                                TantinColors.saffron,
                                TantinColors.success,
                              ][i % 3],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                  _buildSection('Progress & Counters', [
                    const Row(
                      children: [
                        ProgressRing(value: 65, total: 100),
                        SizedBox(width: 24),
                        CountUp(
                          value: 12500,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: TantinColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ]),
                  _buildSection('Segmented', [
                    Segmented<int>(
                      value: _segmentedValue,
                      onChange: (v) => setState(() => _segmentedValue = v),
                      options: const [
                        SegmentedOption(value: 1, label: 'Option 1'),
                        SegmentedOption(
                          value: 2,
                          label: 'Option 2',
                          count: '3',
                        ),
                      ],
                    ),
                  ]),
                  _buildSection('Empty Block', [
                    EmptyBlock(
                      title: 'No Data Found',
                      body: 'This is what an empty block looks like.',
                      action: 'Create new',
                      onAction: () {},
                    ),
                  ]),
                  _buildSection('Sheet', [
                    TnButton(
                      child: const Text('Open Sheet'),
                      onPressed: () => setState(() => _sheetOpen = true),
                    ),
                  ]),
                  _buildSection('Skeleton', [
                    const Skel(height: 60),
                    const SizedBox(height: 8),
                    const Skel(height: 20, width: 200),
                  ]),
                ],
              ),
            ),
          ),
          Sheet(
            open: _sheetOpen,
            onClose: () => setState(() => _sheetOpen = false),
            title: 'Example Sheet',
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Center(child: Text('Sheet Content')),
            ),
          ),
          const Toast(
            toast: ToastData(
              msg: 'Components loaded correctly!',
              type: ToastType.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TnCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: TantinColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
