// English version of the Terms and Privacy Policy (see legal_documents.dart
// for the Spanish original, which is the authoritative text). It keeps the
// same structure and order. This translation has not been reviewed by a
// lawyer.

import 'legal_documents.dart';

class LegalDocumentsEn {
  const LegalDocumentsEn._();

  static const terms = LegalDocument(
    title: 'Terms and Conditions',
    intro: [
      LegalParagraph(
        'These Terms and Conditions (the "Terms") govern your use of the '
        'NutriLife application (the "App"), offered by $kLegalOwnerName, '
        'domiciled in $kLegalOwnerCity, Colombia ("we", "us"). By creating an '
        'account and checking the acceptance box, you enter into an agreement '
        'with us by electronic means, valid under Law 527 of 1999 (Colombia\'s '
        'law on electronic commerce and digital signatures). If you do not '
        'agree to these Terms, do not use the App.',
      ),
      LegalNote(
        'NutriLife is a general nutrition information and tracking tool. It is '
        'not a medical service and does not replace the diagnosis, treatment '
        'or advice of a doctor, nutritionist or other health professional.',
      ),
    ],
    sections: [
      LegalSection('1. The service', [
        LegalParagraph(
          'NutriLife lets you log your meals and your weight, check your calorie '
          'intake against an estimated daily goal, manage a virtual fridge and '
          'chat with an artificial intelligence assistant that suggests recipes '
          'and food ideas.',
        ),
        LegalParagraph(
          'The service is free and is funded by advertising: on the free plan '
          'you will see ads served by Google AdMob. We may add, modify or '
          'remove features to improve the App.',
        ),
      ]),
      LegalSection('2. Requirements to use the App', [
        LegalBullets([
          'You must be over 18 years old. If you are 16 or 17, you may only use '
              'the App with the authorization of your parent or legal '
              'guardian, who accepts these Terms on your behalf.',
          'You must provide truthful information and keep it up to date.',
          'You are responsible for keeping your password confidential and for '
              'the activity of your account. Let us know immediately if you '
              'suspect unauthorized use.',
        ]),
      ]),
      LegalSection('3. Health information and AI-generated content', [
        LegalBullets([
          'Calorie goals, nutritional values and recipes are estimates and may '
              'contain errors or not fit your situation.',
          'The assistant\'s answers are generated automatically using '
              'artificial intelligence. They may be inaccurate, incomplete or '
              'unsuitable for you. Use your own judgment before following them.',
          'Always check the ingredients if you have allergies, intolerances or '
              'dietary restrictions. The App does not guarantee that a recipe '
              'is free of allergens.',
          'Consult a health professional before changing your diet, especially '
              'if you are pregnant or breastfeeding, have a medical condition '
              '(such as diabetes, kidney disease or eating disorders), take '
              'medication or are looking for rapid weight changes.',
          'In a medical emergency, contact the emergency line 123 immediately.',
        ]),
      ]),
      LegalSection('4. Permitted use', [
        LegalParagraph(
          'You agree to use the App lawfully and for personal purposes only. '
          'The following is not allowed:',
        ),
        LegalBullets([
          'Trying to access accounts, data or systems that do not belong to '
              'you, or breaching the security of the App.',
          'Using the App or the assistant to generate content that is illegal, '
              'offensive, promotes dangerous eating behaviors or infringes '
              'third-party rights.',
          'Automating requests, overloading the service or bypassing usage '
              'limits.',
          'Copying, modifying, decompiling or reselling the App or its '
              'contents, except as permitted by law.',
        ]),
        LegalParagraph(
          'If you breach these Terms, we may suspend or close your account, '
          'notifying you beforehand whenever possible.',
        ),
      ]),
      LegalSection('5. Your data', [
        LegalParagraph(
          'The processing of your personal data is governed by our Privacy and '
          'Personal Data Processing Policy, which is part of these Terms.',
        ),
      ]),
      LegalSection('6. Intellectual property', [
        LegalParagraph(
          'The App, its design, brand, logos, texts and code belong to us or '
          'to our respective licensors, and are protected by copyright and '
          'industrial property laws. We grant you a personal, free, '
          'non-exclusive and non-transferable license to use the App in '
          'accordance with these Terms. Some third-party software components '
          'are used under their own open-source licenses.',
        ),
        LegalParagraph(
          'The data you log remains yours. You authorize us to store and '
          'process it only to provide you with the service.',
        ),
      ]),
      LegalSection('7. Future payments and subscriptions', [
        LegalParagraph(
          'If we offer paid features in the future (for example, NutriLife '
          'Premium), before charging you we will inform you of the total '
          'price, the billing frequency, the renewal and cancellation '
          'conditions, and your right of withdrawal under Article 47 of Law '
          '1480 of 2011 (Colombia\'s Consumer Statute). Payments made through '
          'Google Play are also governed by Google Play\'s terms.',
        ),
      ]),
      LegalSection('8. Service availability', [
        LegalParagraph(
          'We make reasonable efforts to keep the App running continuously, but '
          'there may be interruptions due to maintenance, technical failures or '
          'causes beyond our control, such as failures of internet or '
          'artificial intelligence providers.',
        ),
      ]),
      LegalSection('9. Liability', [
        LegalParagraph(
          'To the extent permitted by Colombian law, we will not be liable for '
          'damages arising from health or dietary decisions you make based '
          'solely on the information in the App without consulting a '
          'professional, nor for interruptions caused by force majeure, acts '
          'of God or third-party actions. Nothing in these Terms limits the '
          'rights granted to you by Law 1480 of 2011 or excludes our liability '
          'in cases where the law does not allow it.',
        ),
      ]),
      LegalSection('10. Termination', [
        LegalParagraph(
          'You may stop using the App and delete your account at any time, from '
          'Profile → Delete account. When you delete it, your data is erased as '
          'described in the Privacy Policy.',
        ),
      ]),
      LegalSection('11. Changes to these Terms', [
        LegalParagraph(
          'We may update these Terms. If the changes are substantial, we will '
          'notify you in the App or by email with reasonable advance notice. If '
          'you keep using the App after they take effect, you will be deemed to '
          'have accepted them; if you do not agree, you can delete your '
          'account.',
        ),
      ]),
      LegalSection('12. Governing law and dispute resolution', [
        LegalParagraph(
          'These Terms are governed by the laws of the Republic of Colombia. '
          'Before turning to other avenues, we invite you to write to us to '
          'seek a direct solution. As a consumer, you may turn to the '
          'Superintendence of Industry and Commerce (SIC) or to the competent '
          'courts of Colombia.',
        ),
      ]),
      LegalSection('13. Contact', [
        LegalParagraph(
          'For questions, complaints or claims about these Terms, write to us '
          'at $kLegalContactEmail.',
        ),
      ]),
    ],
  );

  static const privacy = LegalDocument(
    title: 'Privacy Policy',
    intro: [
      LegalParagraph(
        'This policy explains what personal data the NutriLife application '
        '(the "App") collects, what we use it for, who we share it with and '
        'how you can exercise your rights. It is issued in compliance with '
        'Statutory Law 1581 of 2012 (Colombia\'s personal data protection '
        'law), Decree 1074 of 2015 (which compiles Decree 1377 of 2013) and '
        'other Colombian regulations on personal data protection (Habeas '
        'Data).',
      ),
    ],
    sections: [
      LegalSection('1. Data controller', [
        LegalNote(
          'Controller: $kLegalOwnerName\n'
          'Domicile: $kLegalOwnerCity, Colombia\n'
          'Email for requests, inquiries and claims: $kLegalContactEmail',
        ),
      ]),
      LegalSection('2. Data we collect', [
        LegalBullets([
          'Account: name, email address and password (stored encrypted with a '
              'hashing algorithm, never in plain text).',
          'Physical profile and goal: age, height, weight history and '
              'nutritional goal (lose, maintain or gain weight).',
          'Nutrition: logged meals, custom foods, foods in your virtual fridge '
              'and saved recipes.',
          'Conversations: messages you write to the AI assistant and its '
              'replies.',
          'Advertising: your device\'s advertising identifier, your IP '
              'address and general device information, collected by Google '
              'AdMob to show you ads on the free plan.',
          'Technical data: IP address, date and time of requests, actions '
              'performed in the App and errors, for security and diagnostics.',
        ]),
        LegalParagraph(
          'The sex you choose in your profile is stored only on your device and '
          'is not sent to our servers.',
        ),
        LegalParagraph(
          'NutriLife does not access your precise location, contacts, camera, '
          'microphone or photos.',
        ),
      ]),
      LegalSection('3. Sensitive data', [
        LegalParagraph(
          'Your weight, height, goal and eating habits may be considered '
          'health-related data and, therefore, sensitive data under Article 5 '
          'of Law 1581 of 2012. We inform you that:',
        ),
        LegalBullets([
          'You are not required to provide this data. Without it, the App cannot '
              'calculate your calorie goal or personalize its recommendations.',
          'We only process it with your prior, express and informed '
              'authorization, which you give by accepting this policy during '
              'sign-up.',
          'No feature of the App is conditional on you providing more '
              'sensitive data than is necessary for that feature.',
        ]),
      ]),
      LegalSection('4. Purposes of processing', [
        LegalBullets([
          'To create and manage your account and let you sign in.',
          'To calculate your daily calorie goal and show you your intake and '
              'progress.',
          'To generate personalized answers, recipes and suggestions with the '
              'artificial intelligence assistant.',
          'To keep your history of meals, weight, recipes and conversations so '
              'you can review it.',
          'To protect the security of the App, prevent abuse and diagnose '
              'failures.',
          'To handle your requests, inquiries and claims.',
          'To produce internal, anonymous statistics to improve the service.',
          'To show ads on the free plan, through Google AdMob.',
          'To send you communications about how the service works (not '
              'advertising).',
        ]),
        LegalParagraph(
          'We do not sell or rent your personal data. Your profile, weight, '
          'meals and conversations are never shared with advertisers.',
        ),
      ]),
      LegalSection('5. Who we share your data with', [
        LegalParagraph(
          'We only share data with providers that help us deliver the service '
          'and that act as data processors, following our instructions:',
        ),
        LegalBullets([
          'Artificial intelligence provider (OpenAI, United States): receives '
              'the text of your messages to the assistant, your name and the '
              'foods you attach, solely to generate the reply.',
          'Cloud infrastructure providers: host our servers and databases.',
          'Google AdMob (Google LLC, United States): serves the ads on the '
              'free plan and, to do so, receives the advertising identifier, '
              'the IP address and general device information. It processes '
              'this data according to Google\'s privacy policy.',
        ]),
        LegalParagraph(
          'Personalized ads are only shown if you allow them: on iPhone, by '
          'accepting the tracking prompt; on Android, you can reset or delete '
          'your advertising identifier in Settings → Privacy → Ads. If you do '
          'not allow it, you will see generic ads. Premium plan users do not '
          'see ads.',
        ),
        LegalParagraph(
          'Some of these providers are located outside Colombia, so '
          'international data transmission may occur. By accepting this policy '
          'you expressly authorize that transmission, under the terms of '
          'Article 26 of Law 1581 of 2012 and Decree 1074 of 2015. We require '
          'these providers to maintain adequate levels of protection.',
        ),
        LegalParagraph(
          'If the assistant suggests a YouTube video and you open it, YouTube '
          '(Google) will process your data according to its own policies.',
        ),
        LegalParagraph(
          'We may also hand over data when ordered by a competent authority, '
          'in accordance with the law.',
        ),
      ]),
      LegalSection('6. Your rights as a data subject', [
        LegalParagraph(
          'Under Article 8 of Law 1581 of 2012, you have the right to:',
        ),
        LegalBullets([
          'Know, update and correct your personal data.',
          'Request proof of the authorization you gave us.',
          'Be informed about how we have used your data.',
          'File complaints with the Superintendence of Industry and Commerce '
              '(SIC) for violations of the law, once the inquiry or claim '
              'process with us has been exhausted.',
          'Revoke the authorization and/or request the deletion of your data.',
          'Access your personal data free of charge.',
        ]),
        LegalParagraph(
          'You can update your profile directly in the App, under Profile → '
          'Settings.',
        ),
      ]),
      LegalSection('7. How to delete your account and data', [
        LegalParagraph('You can delete your account at any time:'),
        LegalBullets([
          'From the App: Profile → Delete account.',
          'By email: writing to $kLegalContactEmail from the email address '
              'associated with your account.',
        ]),
        LegalParagraph(
          'When you delete your account, we permanently erase your profile, '
          'weight history, meals, fridge, recipes, custom foods, conversations '
          'and associated activity logs. We only keep an anonymous record that '
          'a deletion took place, which does not allow you to be identified. '
          'Data stored only on your device is erased when you uninstall the '
          'App.',
        ),
      ]),
      LegalSection('8. Inquiries and claims', [
        LegalParagraph(
          'To exercise your rights, write to $kLegalContactEmail stating your '
          'name, your account email, a description of your request and, if '
          'applicable, any documents you want to rely on.',
        ),
        LegalParagraph(
          'Inquiries will be handled within a maximum of ten (10) business '
          'days from receipt. If that is not possible, we will tell you the '
          'reasons and the response date, which will not exceed five (5) '
          'additional business days (Article 14, Law 1581 of 2012).',
        ),
        LegalParagraph(
          'Claims: if you believe your data should be corrected, updated or '
          'deleted, or you notice a breach, you may file a claim. If it is '
          'incomplete, we will ask you to complete it within the following '
          'five (5) days; if two (2) months pass without you completing it, '
          'the claim will be deemed withdrawn. We will respond within a '
          'maximum of fifteen (15) business days from the day after receipt, '
          'extendable by up to eight (8) additional business days, with prior '
          'notice (Article 15, Law 1581 of 2012).',
        ),
      ]),
      LegalSection('9. Security', [
        LegalParagraph(
          'We apply reasonable technical and administrative measures to protect '
          'your data: encrypted connections (HTTPS), hashed password storage, '
          'restricted access to the database and token authentication on every '
          'request. No system is completely infallible; if we detect an '
          'incident that affects your data, we will inform you and report it '
          'to the SIC when the law requires it.',
        ),
      ]),
      LegalSection('10. Data retention', [
        LegalParagraph(
          'We keep your data while your account is active and as long as it is '
          'necessary for the purposes described. When you delete your account, '
          'we erase it as explained in section 7, unless a legal obligation '
          'requires us to keep some of it for longer.',
        ),
      ]),
      LegalSection('11. Minors', [
        LegalParagraph(
          'NutriLife is intended for people over 18 years old. Teenagers aged '
          '16 and 17 may only use it with the authorization of their parent or '
          'legal guardian, and always with respect for their best interests, '
          'in accordance with Article 7 of Law 1581 of 2012. Registration of '
          'minors under 16 is not allowed. If you are a legal guardian and '
          'believe a minor gave us data without authorization, write to us so '
          'we can delete it.',
        ),
      ]),
      LegalSection('12. Health notice', [
        LegalParagraph(
          'The information provided by NutriLife is general and does not '
          'replace the advice of a doctor or nutritionist. See the Terms and '
          'Conditions for more detail.',
        ),
      ]),
      LegalSection('13. Changes and validity', [
        LegalParagraph(
          'If we make substantial changes to this policy, we will notify you in '
          'the App or by email before they take effect and, when the law '
          'requires it, we will ask for your authorization again. This policy '
          'is effective from $kLegalUpdatedAtEn. NutriLife\'s databases will '
          'remain in effect for as long as the service is provided.',
        ),
      ]),
    ],
  );
}
