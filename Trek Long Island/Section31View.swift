import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(PDFKit)
import PDFKit
#endif

@MainActor
struct Section31View: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL

    private let truthURL = URL(string: "https://memory-alpha.fandom.com/wiki/Truth")!
    private let harassmentPolicyURL = URL(string: "https://treklongisland.com/harassment-policy/")!
    private let supportURL = URL(string: "https://buymeacoffee.com/myevcompanionapp")!
    private let iosRepoURL = URL(string: "https://github.com/rike4545/Trek-Long-Island")!
    private let androidRepoURL = URL(string: "https://github.com/rike4545/TrekLongIslandAndroid")!
    private let taxReferenceLinks: [Section31ReferenceLink] = [
        .init(
            title: "Publication 843",
            summary: "New York State sales tax guide for exempt organizations, including registration and collection duties when taxable sales are made.",
            url: URL(string: "https://www.tax.ny.gov/pdf/publications/sales/pub843.pdf")!
        ),
        .init(
            title: "Amusement Parks - Admission, Ride, and Other Charges",
            summary: "Tax Bulletin TB-ST-30 covering taxable admission charges and amusement-park admission rules.",
            url: URL(string: "https://www.tax.ny.gov/pubs_and_bulls/tg_bulletins/st/amusement_parks.htm")!
        ),
        .init(
            title: "Admission Charges to a Place of Amusement",
            summary: "Tax Bulletin TB-ST-8 covering New York sales tax on admission charges to places of amusement.",
            url: URL(string: "https://www.tax.ny.gov/pubs_and_bulls/tg_bulletins/st/admission_charges.htm")!
        )
    ]

    private let evidenceDocs: [Section31EvidenceDocument] = [
        .init(
            title: "Paramount Openline IP Infringement Complaint",
            fileName: "EthicsPoint",
            summary: "EthicsPoint/Paramount Openline report submitted May 4, 2026 for alleged unauthorized Star Trek intellectual property use. The supplied follow-up page states the matter was forwarded to Paramount's law department for handling."
        ),
        .init(
            title: "U.S. Copyright Office Registration: Trek Long Island",
            fileName: "Copyright Office - Trek Long Island Registration 1-15133681261",
            fileExtension: "png",
            summary: "Copyright Office email screenshot confirming that the work \"Trek Long Island\" was registered. Preserved as objective evidence that B. Carroll owns the finalized, issued, and filed copyright for Trek Long Island, registration 1-15133681261. The screenshot also shows U.S. Copyright Office Visual Arts Division correspondence and thread ID 1-6Z431TW."
        ),
        .init(
            title: "Paramount CBS EthicsPoint Unauthorized Star Trek IP Report",
            fileName: "Paramount CBS EthicsPoint - Unauthorized Star Trek IP Report 499310301501",
            fileExtension: "png",
            summary: "NAVEX EthicsPoint confirmation screenshot for a Paramount/CBS report concerning unauthorized use of Star Trek intellectual property. The screenshot shows report key 499310301501 and instructions to allow 2-3 business days for processing and review."
        ),
        .init(
            title: "New York Tax Evasion and Fraud Report Confirmation",
            fileName: "Report Tax Evasion and Fraud",
            summary: "New York Department of Taxation and Finance confirmation page showing receipt of a report involving Trek Long Island Corp on May 4, 2026 at 4:58 PM. Confirmation number RTEV0504202639302."
        ),
        .init(
            title: "Unpaid Programming and Mobile Apps Invoice",
            fileName: "PayPal Invoice INV2-CMXR-BXSY-QYFQ-SV5L",
            summary: "PayPal invoice for the remaining balance for iOS and Android app labor after a $300 deposit was paid by the event organizer. Invoice 0004 shows $2,293.90 USD due on Apr 30, 2026."
        ),
        .init(
            title: "Sales Tax Liability Notice to Trek Long Island Corp Agent",
            fileName: "Gmail - Sales Tax Needed to be Collected for Admission Tickets",
            summary: "Gmail thread from Apr 30, 2026 documenting notice to Stefanie at Trek Long Island that New York sales tax needed to be collected for admission tickets, with official New York State tax guidance links included in the message."
        ),
        .init(
            title: "App Sponsorship",
            fileName: "Gmail - App Sponsorship",
            summary: "Gmail export discussing a proposed $1,500 app sponsorship tier, sponsor visibility in the iPhone app, and platform planning."
        ),
        .init(
            title: "App Sponsorship Follow-Up",
            fileName: "Gmail - App Sponsorship - New",
            summary: "Additional Gmail export for app sponsorship discussions, preserved as a separate document from the earlier sponsorship thread."
        ),
        .init(
            title: "New Apple iPhone App Changes",
            fileName: "Gmail - New Apple iPhone App - Trek Long Island Changes",
            summary: "Gmail export covering requested iPhone app changes and related Trek Long Island planning."
        ),
        .init(
            title: "Trek Long Island",
            fileName: "Gmail - Trek Long Island",
            summary: "Gmail export for the Trek Long Island thread included in the Section 31 dossier."
        ),
        .init(
            title: "Trek Long Island Follow-Up",
            fileName: "Gmail - Trek Long Island - New",
            summary: "Additional Gmail export for a Trek Long Island thread, preserved separately from the earlier similarly named file."
        ),
        .init(
            title: "Trek Long Island Google Calendars",
            fileName: "Gmail - Trek Long Island Google Calenders - New",
            summary: "Gmail export covering Trek Long Island Google calendar materials and related coordination."
        ),
        .init(
            title: "Amazon Print on Demand Merch",
            fileName: "Gmail - Question Regarding Special Amazon Print on Demand for Merch",
            summary: "Gmail export about special Amazon print-on-demand merchandise questions."
        ),
        .init(
            title: "Trek LI 2025 iPhone App Review Submission",
            fileName: "Gmail - Trek LI 2025 Apple iPhone App Submitted for Apple for Review and Associated Updates",
            summary: "Gmail export covering the Apple review submission and associated app updates."
        ),
        .init(
            title: "Trek LI 2025 iPhone App Review Submission Follow-Up",
            fileName: "Gmail - Trek LI 2025 Apple iPhone App Submitted for Apple for Review and Associated Updates - New",
            summary: "Additional Gmail export covering Apple review submission and associated update details, preserved separately from the earlier similarly named file."
        ),
        .init(
            title: "You've Got Money",
            fileName: "Gmail - You've got money",
            summary: "Gmail export for the payment-related thread included in the Section 31 dossier."
        ),
        .init(
            title: "Trek LI 2025 iPhone App",
            fileName: "Gmail - Trek LI 2025 Apple iPhone App",
            summary: "Gmail export for the Trek LI 2025 Apple iPhone app thread."
        ),
        .init(
            title: "Android Sponsorship or Activation",
            fileName: "Gmail - Possible Sponsorship for Trek Long Island Android App or Possible Activation",
            summary: "Gmail export about possible sponsorship or activation for the Trek Long Island Android app."
        ),
        .init(
            title: "Hostile Review: Bryan is a child",
            fileName: "Hostile Review - Bryan is a child",
            fileExtension: "png",
            summary: "Screenshot of a one-star review containing personal insults and claims about the app."
        ),
        .init(
            title: "Hostile Review: Do Not Install Fake App",
            fileName: "Hostile Review - Do Not Install Fake App",
            fileExtension: "png",
            summary: "Screenshot of a one-star review describing the app as fake or fraudulent."
        ),
        .init(
            title: "Hostile Review: Fraud Cease and Desist",
            fileName: "Hostile Review - Fraud Cease and Desist",
            fileExtension: "png",
            summary: "Screenshot of a one-star review alleging fraud and a cease-and-desist notice."
        ),
        .init(
            title: "Hostile Review: Scam No Connection",
            fileName: "Hostile Review - Scam No Connection",
            fileExtension: "png",
            summary: "Screenshot of a one-star review alleging the developer has no convention connection."
        ),
        .init(
            title: "App Review: Scam / Child Insult",
            fileName: "App Review - Scam Child Garbage",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"Scam\" dated May 5, 2026 by Captainflores, containing a personal insult about whether the app was made by a child."
        ),
        .init(
            title: "App Review: Fraud / Fake Conference Claim",
            fileName: "App Review - Fraud Fake Conference",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"Fraud\" dated Apr 14, 2026 by Holmesian8, alleging the app is fake and not created by the actual conference."
        ),
        .init(
            title: "App Review: Do Not Install / Official Warnings Claim",
            fileName: "App Review - Do Not Install Fake App Official Warnings",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"DO NOT INSTALL! FAKE APP!\" dated Apr 14, 2026 by BambinoPrime, alleging the app is a scam and that official TLI sites or social media warned people about it."
        ),
        .init(
            title: "App Review: Fraudulent App Illegal Use",
            fileName: "App Review - Fraudulent App Illegal Use C Heights",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"Fraudulent App Illegal Use\" dated May 1, 2026 by C. Heights, alleging scam, felony fraud, illegal use of likeness, artwork, and images, illegal merchandise sales, a cease-and-desist, threatened litigation or jail time, and mental illness."
        ),
        .init(
            title: "App Review: Fraud / Cease-and-Desist Claim",
            fileName: "App Review - Fraud Cease and Desist Claim",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"FRAUD\" dated Apr 30, 2026 by FaerieBeth, alleging the creator was served with a cease-and-desist for copyright infringement and violation."
        ),
        .init(
            title: "App Review: Fraudulent App / Stolen Content Claim",
            fileName: "App Review - Fraudulent App Stolen Content",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"Fraudulent app\" dated May 3, 2026 by Svbabe, alleging stolen content from the original creator."
        ),
        .init(
            title: "Public Post: False Convention App Claim",
            fileName: "Public Post - False Convention App Claim",
            fileExtension: "png",
            summary: "Screenshot of a public social media post dated May 2, 2026 alleging a scam artist, false convention app, unauthorized use of convention art, and urging people to delete the app. Preserved as evidence of disputed public claims and the narrative being circulated."
        ),
        .init(
            title: "Hollywood Extras / Olivia Youngers: Characterization After Defamation Warning",
            fileName: "Olivia Youngers Hollywood Extras - Unhinged Man Characterization and Defamation Warning 1",
            fileExtension: "jpg",
            summary: "Screenshot preserving a post attributed to Olivia Youngers / Hollywood Extras characterizing the developer as an \"unhinged man\" and a bully after a message respectfully warned that reposting, posting, or furthering a false narrative could enter libel and defamation territory."
        ),
        .init(
            title: "Hollywood Extras / Olivia Youngers: Burner Accounts and Threatening Emails Claim",
            fileName: "Olivia Youngers Hollywood Extras - Burner Accounts Threatening Emails Claim",
            fileExtension: "jpg",
            summary: "Screenshot preserving a comment and follow-up characterization attributed to Olivia Youngers, including claims of burner accounts, being followed across social media, two threatening emails, a cease-and-desist, and local police notification. Preserved as evidence of additional disputed characterizations after attempts to request restraint."
        ),
        .init(
            title: "Hollywood Extras / Olivia Youngers: Bullies and Threats Post",
            fileName: "Olivia Youngers Hollywood Extras - Bullies and Threats Janeway Post",
            fileExtension: "jpg",
            summary: "Screenshot preserving a shared post using a Captain Janeway quote about bullies and threats, attributed in the supplied evidence set to the same public narrative around the developer."
        ),
        .init(
            title: "Hollywood Extras / Olivia Youngers: Duplicate Characterization Capture",
            fileName: "Olivia Youngers Hollywood Extras - Unhinged Man Characterization and Defamation Warning 2",
            fileExtension: "jpg",
            summary: "Second screenshot capture of the Olivia Youngers / Hollywood Extras characterization and the underlying respectful warning message. Preserved separately because it was supplied as a distinct evidence image."
        ),
        .init(
            title: "App Review: Fake App / Credit Card Fraud Claim",
            fileName: "App Review - Fake App Credit Card Fraud fitgeek248",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"Fake app\" dated Jun 6, 2026 by fitgeek248, falsely alleging the app caused crashes, stole personal information, triggered credit card fraud calls, and claiming the app has no connection to the convention. This app does not collect, transmit, or store any personal or financial information. The source code is publicly available on GitHub for verification."
        ),
        .init(
            title: "App Review: Fake / Stolen Likeness Claim",
            fileName: "App Review - Fake Stolen Likeness ADP325",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"Fake\" dated Jun 10, 2026 by ADP325, alleging stolen likeness, art, and use of the Trek Long Island convention name to illegally profit from work the reviewer claims the creator was not part of."
        ),
        .init(
            title: "App Review: Scam / Proof Demand",
            fileName: "App Review - Scam Scammer Captainflores Jun 2026",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"Scam\" dated May 31, 2026 by Captainflores, stating \"How much proof does Apple need? Scammer.\" Preserved as evidence of disparaging public claims."
        ),
        .init(
            title: "App Review: Fraud / Copyright Checklist Claims",
            fileName: "App Review - Fraud Copyright Checklist FaerieBeth",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"FRAUD\" dated Jun 9, 2026 by FaerieBeth, alleging cease-and-desist service, copyright infringement, fraudulent contracted-work claims, stolen art, and use of legal terms the reviewer claims the developer does not understand."
        ),
        .init(
            title: "App Review: Do Not Download / Dangerous Scam Claim",
            fileName: "App Review - Do Not Download Dangerous Scam Itscowcraft1020",
            fileExtension: "png",
            summary: "Screenshot of a one-star review titled \"DO NOT DOWNLOAD\" dated Jun 9, 2026 by Itscowcraft1020, alleging the app is fake, not connected to Trek LI, unauthorized to use a logo, includes in-app purchases, and is a dangerous scam."
        )
    ]

    private let videoLinks: [Section31VideoLink] = [
        .init(
            title: "Section 31 Transmission 1",
            summary: "YouTube Short for the Section 31 dossier.",
            url: URL(string: "https://www.youtube.com/shorts/1l-xc6-rANM")!
        ),
        .init(
            title: "Section 31 Transmission 2",
            summary: "Second YouTube Short for the Section 31 dossier.",
            url: URL(string: "https://www.youtube.com/shorts/ZZKId6HhVHo")!
        ),
        .init(
            title: "Section 31 Transmission 3",
            summary: "Third YouTube Short for the Section 31 dossier.",
            url: URL(string: "https://www.youtube.com/shorts/nK8lK1Le6EY")!
        )
    ]

    @State private var selectedPDF: Section31PDFDocument?
    @State private var selectedImage: Section31ImageDocument?

    var body: some View {
        ZStack {
            TLITheme.backgroundGradient(scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    truthCard
                    harassmentPolicyCard
                    defamationContextCard
                    reviewDefamationElementsCard
                    developerImpactCard
                    developmentPaymentCard
                    intellectualPropertyAndTaxComplaintCard
                    supportLinksCard
                    taxCollectionCard
                    evidenceSection
                    videoCard
                    footerNote
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Section 31")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    openURL(truthURL)
                } label: {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("Open Truth reference")
            }
        }
        #if canImport(PDFKit)
        .sheet(item: $selectedPDF) { document in
            Section31PDFSheet(document: document)
                .ignoresSafeArea()
        }
        #endif
        #if canImport(UIKit)
        .sheet(item: $selectedImage) { document in
            Section31ImageSheet(document: document)
                .ignoresSafeArea()
        }
        #endif
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.thinMaterial)

                    Image(systemName: "eye.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RisaTheme.accent(scheme))
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Section 31")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))

                    Text("Transparency notes, source documents, and public reference links collected for review.")
                        .font(.subheadline)
                        .foregroundStyle(RisaTheme.textSecondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("For Fans, By Fans. Let Truth Be Free.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))

                Text("This page preserves records that may help users evaluate public claims about the app and its development history.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                Text("The materials are presented as supplied source documents and references. They are not legal conclusions, and readers should review the documents directly.")
                    .font(.footnote)
                    .foregroundStyle(RisaTheme.textSecondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                Text("Feedback, corrections, and support requests should be submitted through the app support form.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(RisaTheme.textPrimary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                Text("This page keeps reference links and the local document packet together in one place.")
                    .font(.footnote)
                    .foregroundStyle(RisaTheme.textMuted(scheme))
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var truthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "Reference", systemImage: "book.closed.fill")

            Text("Truth")
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text("Memory Alpha describes truth as being in accordance with fact or reality, with lying framed as concealing the truth.")
                .font(.body)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                openURL(truthURL)
            } label: {
                Label("Open on Memory Alpha", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var harassmentPolicyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "Policy Note", systemImage: "exclamationmark.shield.fill")

            Text("Trek Long Island Harassment Policy")
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text("The Trek Long Island harassment policy is linked here as a public reference for behavior standards, incident reporting, and online conduct connected to the convention.")
                .font(.body)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                openURL(harassmentPolicyURL)
            } label: {
                Label("Open Harassment Policy", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var defamationContextCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "General Context", systemImage: "scale.3d")

            Text("Public Claims and Written Reviews")
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text("Some submitted screenshots include written reviews and public allegations about the app or developer. This page preserves those materials alongside source documents so readers can evaluate the claims in context.")
                .font(.body)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                contextPoint("Source documents", "Invoices, emails, screenshots, reports, and public references are grouped here for direct review.")
                contextPoint("Clear sourcing", "Each item is labeled by document type, title, or source so users can distinguish evidence from commentary.")
                contextPoint("Neutral presentation", "This section avoids asking users to accept a conclusion and instead points them to the underlying records.")
                contextPoint("Corrections welcome", "If a document, title, or summary needs correction, use the support form so it can be reviewed.")
            }

            Text("This note is general context only and is not legal advice.")
                .font(.footnote)
                .foregroundStyle(RisaTheme.textMuted(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var reviewDefamationElementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "Review Analysis", systemImage: "quote.bubble.fill")

            Text("Review Screenshots and Defamation Elements")
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text("The review screenshots are included because they contain written factual allegations and personal identifiers that may be relevant to a defamation analysis. The app presents them as source records, not as a legal finding.")
                .font(.body)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                contextPoint("Statement presented as fact", "Examples include claims that the app is fake, fraudulent, stolen, not connected to the conference, or subject to a cease-and-desist.")
                contextPoint("Publication", "The statements appear in public App Store reviews.")
                contextPoint("Identification", "Several reviews identify the app, the developer, or both.")
                contextPoint("Potential harm", "The reviews ask users not to install, use, or report the app and include accusations of fraud, theft, or illegality.")
                contextPoint("Truth or falsity to evaluate", "The accompanying invoices, emails, report confirmations, and app records are preserved so the factual claims can be evaluated against source documents.")
            }

            Text("This is not legal advice and does not ask users to reach a legal conclusion.")
                .font(.footnote)
                .foregroundStyle(RisaTheme.textMuted(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var developerImpactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "Developer Impact", systemImage: "person.crop.circle.badge.exclamationmark")

            Text("Time, Labor, and Support Burden")
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text("These records are also preserved because public allegations, review responses, unpaid development work, ongoing maintenance, and support handling require real time, labor, and cost from the developer.")
                .font(.body)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Text("This context is included so users can understand the practical impact while still reviewing the source documents directly.")
                .font(.footnote)
                .foregroundStyle(RisaTheme.textMuted(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "Evidence", systemImage: "doc.text.fill")

            ForEach(evidenceDocs) { document in
                evidenceCard(document)
            }
        }
    }

    private var developmentPaymentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "Development Record", systemImage: "receipt.fill")

            Text("App Development Payment Record")
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text("The app development record reflects that the event organizer paid a $300 deposit toward building the app. The final invoice for remaining app development work has not been paid. The developer also paid for his own admission ticket to attend the convention.")
                .font(.body)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Text("The bundled invoice and related email records are included so users can review the payment history directly. This note is a factual summary of the supplied records and is not legal advice.")
                .font(.footnote)
                .foregroundStyle(RisaTheme.textMuted(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var intellectualPropertyAndTaxComplaintCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "Source Records", systemImage: "doc.badge.exclamationmark.fill")

            Text("IP and New York Sales Tax Report Records")
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text("The document packet includes a Paramount Openline/EthicsPoint submission concerning alleged unauthorized Star Trek intellectual property use. The supplied follow-up page states that the matter was forwarded to Paramount's law department for handling.")
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Text("The packet also includes a New York Department of Taxation and Finance report confirmation involving Trek Long Island Corp. The supplied confirmation page states that the Tax Department received the report on May 4, 2026 at 4:58 PM, with confirmation number RTEV0504202639302.")
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Text("This section preserves report confirmations and supporting details as supplied records; it is not a legal conclusion.")
                .font(.footnote)
                .foregroundStyle(RisaTheme.textMuted(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var taxCollectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "Sales Tax References", systemImage: "building.columns.fill")

            Text("New York Admission Ticket Tax References")
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text("Official New York State tax guidance is linked here as background for the supplied sales-tax report confirmation and related email records.")
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(taxReferenceLinks) { reference in
                    referenceLinkCard(reference)
                }
            }

            Text("This is included as a source packet and is not legal or tax advice.")
                .font(.footnote)
                .foregroundStyle(RisaTheme.textMuted(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private var videoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "Video", systemImage: "play.rectangle.fill")

            Text("Section 31 Transmissions")
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text("Linked YouTube Shorts for the Section 31 dossier.")
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(videoLinks) { video in
                    videoLinkCard(video)
                }
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private func videoLinkCard(_ video: Section31VideoLink) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(video.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text(video.summary)
                .font(.footnote)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    openURL(video.url)
                } label: {
                    Label("Watch on YouTube", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    openURL(video.url)
                } label: {
                    Label("Open in Browser", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.35), lineWidth: 1)
        )
    }

    private func referenceLinkCard(_ reference: Section31ReferenceLink) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(reference.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text(reference.summary)
                .font(.footnote)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    openURL(reference.url)
                } label: {
                    Label("Open Website", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    openURL(reference.url)
                } label: {
                    Label("Open in Browser", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.35), lineWidth: 1)
        )
    }

    private var supportLinksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow(title: "Links", systemImage: "link.circle.fill")

            Text("Follow the project, support the work, and review both codebases directly.")
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                actionButton(
                    title: "Buy Me a Coffee",
                    systemImage: "cup.and.saucer.fill",
                    url: supportURL,
                    prominent: true
                )

                actionButton(
                    title: "View iOS GitHub Repo",
                    systemImage: "iphone.gen3",
                    url: iosRepoURL,
                    prominent: false
                )

                actionButton(
                    title: "View Android GitHub Repo",
                    systemImage: "apps.iphone",
                    url: androidRepoURL,
                    prominent: false
                )
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.45), lineWidth: 1)
        )
    }

    private func evidenceCard(_ document: Section31EvidenceDocument) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(document.title)
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text(document.summary)
                .font(.subheadline)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    openEvidence(document)
                } label: {
                    Label(document.openButtonTitle, systemImage: document.systemImage)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(RisaTheme.cardStroke(scheme).opacity(0.35), lineWidth: 1)
        )
    }

    private var footerNote: some View {
        Text("Evidence PDFs are bundled from the files you supplied, tax references open from official New York State pages, and the linked video opens from YouTube.")
            .font(.footnote)
            .foregroundStyle(RisaTheme.textMuted(scheme))
            .padding(.top, 2)
    }

    private func labelRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(RisaTheme.accent(scheme))
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))
        }
    }

    private func contextPoint(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text(detail)
                .font(.footnote)
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func actionButton(title: String, systemImage: String, url: URL, prominent: Bool) -> some View {
        if prominent {
            Button {
                openURL(url)
            } label: {
                Label(title, systemImage: systemImage)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                openURL(url)
            } label: {
                Label(title, systemImage: systemImage)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func openEvidence(_ document: Section31EvidenceDocument) {
        guard let url = evidenceURL(for: document) else { return }

        if document.fileExtension.lowercased() == "png" {
            #if canImport(UIKit)
            selectedImage = Section31ImageDocument(title: document.title, url: url)
            #else
            openURL(url)
            #endif
            return
        }

        #if canImport(PDFKit)
        selectedPDF = Section31PDFDocument(title: document.title, url: url)
        #else
        openURL(url)
        #endif
    }

    private func evidenceURL(for document: Section31EvidenceDocument) -> URL? {
        if let bundled = Bundle.main.url(
            forResource: document.fileName,
            withExtension: document.fileExtension,
            subdirectory: "Resources/Section31 Evidence"
        ) {
            return bundled
        }

        return Bundle.main.url(forResource: document.fileName, withExtension: document.fileExtension)
    }
}

private struct Section31EvidenceDocument: Identifiable {
    let id = UUID()
    let title: String
    let fileName: String
    var fileExtension: String = "pdf"
    let summary: String

    var openButtonTitle: String {
        fileExtension.lowercased() == "pdf" ? "Open PDF" : "Open Screenshot"
    }

    var systemImage: String {
        fileExtension.lowercased() == "pdf" ? "doc.richtext" : "photo"
    }
}

private struct Section31VideoLink: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let url: URL
}

private struct Section31ReferenceLink: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let url: URL
}

private struct Section31PDFDocument: Identifiable {
    let title: String
    let url: URL
    var id: URL { url }
}

private struct Section31ImageDocument: Identifiable {
    let title: String
    let url: URL
    var id: URL { url }
}

#if canImport(UIKit)
private struct Section31ImageSheet: View {
    let document: Section31ImageDocument

    var body: some View {
        NavigationStack {
            ZoomableSection31Image(url: document.url)
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ZoomableSection31Image: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.backgroundColor = .systemBackground

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(contentsOfFile: url.path)
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        context.coordinator.imageView = imageView
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = UIImage(contentsOfFile: url.path)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }
    }
}
#endif

#if canImport(PDFKit)
private struct Section31PDFSheet: View {
    let document: Section31PDFDocument

    var body: some View {
        NavigationStack {
            Section31PDFKitView(url: document.url)
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct Section31PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = UIColor.systemBackground
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}
#endif
