import Foundation
import SourceKittenFramework

public struct PreferSelfInValueTypeRule: ASTRule, ConfigurationProviderRule, SubstitutionCorrectableASTRule,
    AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "prefer_return_self_in_value_type",
        name: "Prefer Return Self In Value Type",
        description: "Prefer return `Self` in value type",
        kind: .metrics,
        nonTriggeringExamples: [
            """
            struct Foo {
                func someFunc() -> Self { return Foo() }
            }
            """,
            """
            class Foo {
                func someFunc() -> Foo { return Foo() }
            }
            """
        ],
        triggeringExamples: [
            """
            struct Foo {
                static func someFunc() -> Foo { return Foo() }
            }
            """,
            """
            struct Foo {
                func someFunc() -> Foo { return Foo() }
            }
            """,
            """
            struct Foo {
                var someComputedProperty: Foo { return Foo() }
            }
            """
        ]
    )

    private let declarationKinds: [SwiftDeclarationKind] = [
        .functionMethodInstance,
        .functionMethodClass,
        .functionMethodStatic,
        .varInstance,
        .varClass
    ]

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .struct else { return [] }
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func violationRanges(in file: SwiftLintFile,
                                kind: SwiftDeclarationKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard declarationKinds.contains(kind) else { return [] }

        let typeNamePattern = "\\w+"
        let pattern = "\\s*(:|->|:)\\s*(?:\(typeNamePattern)\\b|\\(\\s*\\))"

        return file.match(pattern: pattern,
                          excludingSyntaxKinds: SyntaxKind.commentAndStringKinds).compactMap { range in
            let typeNameRegex = regex(typeNamePattern)
            return typeNameRegex.firstMatch(in: file.contents,
                                            options: [],
                                            range: range)?.range
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "Self")
    }
}
