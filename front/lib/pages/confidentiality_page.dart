import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConfidentialityPage extends StatelessWidget {
  const ConfidentialityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.privacy_and_security_policy),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.welcome_message,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                AppLocalizations.of(context)!.information_collection_details,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                AppLocalizations.of(context)!.account_information,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.communication_information,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.usage_data,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.technical_information,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16.0),
              Text(
                AppLocalizations.of(context)!.use_of_information_details,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                AppLocalizations.of(context)!.provide_services,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.personalize_experience,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.ensure_security,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.communicate_updates,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.analyze_trends,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16.0),
              Text(
                AppLocalizations.of(context)!.sharing_information_details,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                AppLocalizations.of(context)!.service_providers,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.legal_obligations,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.protection_of_rights,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16.0),
              Text(
                AppLocalizations.of(context)!.information_security_details,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                AppLocalizations.of(context)!.encryption,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.access_controls,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.monitoring,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.backups,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16.0),
              Text(
                AppLocalizations.of(context)!.your_rights_details,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                AppLocalizations.of(context)!.access_and_correction,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.deletion,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.portability,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.objection,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16.0),
              Text(
                AppLocalizations.of(context)!.data_retention_details,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                AppLocalizations.of(context)!.changes_to_policy_details,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16.0),
              Text(
                AppLocalizations.of(context)!.contact_details,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                AppLocalizations.of(context)!.email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context)!.address,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16.0),
              Text(
                AppLocalizations.of(context)!.acceptance,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
