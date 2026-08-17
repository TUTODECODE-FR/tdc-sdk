// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

const vscode = require('vscode');

// Whitelist des tokens valides (identique au moteur Dart)
const VALID_COLOR_TOKENS = new Set([
  'creme', 'mint', 'lavande', 'ambre', 'coral', 'sky', 'pink', 'emerald', 'cyan', 'gold', 'linux'
]);

const BUILTIN_CATEGORIES = new Set([
  'linux', 'network', 'security', 'cloud', 'crypto', 'development'
]);

const VALID_LEVELS = new Set([
  'beginner', 'intermediate', 'advanced'
]);

/**
 * Port exact du validateur syntaxique Dart TDCParser.validateSyntax
 * @param {vscode.TextDocument} document 
 * @returns {vscode.Diagnostic[]}
 */
function validateTDCDocument(document) {
  const diagnostics = [];
  const text = document.getText();
  const lines = text.split('\n');
  const braceStack = [];
  let inTripleQuote = false;
  let tripleQuoteStartLine = 0;
  let foundCourseBlock = false;
  const declaredCustomCategories = new Set();

  for (let i = 0; i < lines.length; i++) {
    const lineNum = i; // 0-indexed for VS Code
    const line = lines[i].trim();

    if (inTripleQuote) {
      if (line.includes('"""')) {
        inTripleQuote = false;
      }
      continue;
    }

    const tqMatches = line.match(/"""/g);
    const tqCount = tqMatches ? tqMatches.length : 0;
    if (tqCount % 2 !== 0) {
      inTripleQuote = true;
      tripleQuoteStartLine = lineNum;
      continue;
    }

    if (line.length === 0 || line.startsWith('//') || line.startsWith('#')) {
      continue;
    }

    if (line === '}') {
      if (braceStack.length === 0) {
        const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
        diagnostics.push(new vscode.Diagnostic(range, "Accolade fermante '}' en trop sans bloc ouvert.", vscode.DiagnosticSeverity.Error));
      } else {
        braceStack.pop();
      }
      continue;
    }

    // Déclaration category custom "id" {
    const customCatMatch = line.match(/^category\s+custom\s+["']([^"']+)["']\s*\{$/);
    if (customCatMatch) {
      const catId = customCatMatch[1].toLowerCase();
      if (BUILTIN_CATEGORIES.has(catId)) {
        const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
        diagnostics.push(new vscode.Diagnostic(range, `L'identifiant de catégorie custom '${catId}' entre en collision avec une catégorie intégrée.`, vscode.DiagnosticSeverity.Error));
      }
      declaredCustomCategories.add(catId);
      braceStack.push({ type: 'category_custom', line: lineNum });
      continue;
    }

    // Déclaration course "id" {
    const courseMatch = line.match(/^course\s+["']([^"']+)["']\s*\{$/);
    if (courseMatch) {
      if (braceStack.length > 0) {
        const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
        diagnostics.push(new vscode.Diagnostic(range, "Le bloc course ne peut pas être imbriqué.", vscode.DiagnosticSeverity.Error));
      }
      braceStack.push({ type: 'course', line: lineNum });
      foundCourseBlock = true;
      continue;
    }

    if (!foundCourseBlock && braceStack.length === 0) {
      const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
      diagnostics.push(new vscode.Diagnostic(range, `Déclaration 'course "identifiant" {' attendue en début de fichier (trouvé : '${line}').`, vscode.DiagnosticSeverity.Error));
      continue;
    }

    const currentScope = braceStack.length > 0 ? braceStack[braceStack.length - 1].type : 'root';

    if (currentScope === 'category_custom') {
      if (/^label:\s*["']/.test(line)) continue;
      const colorMatch = line.match(/^color:\s*([a-zA-Z0-9_\-\.\+]+)/);
      if (colorMatch) {
        const token = colorMatch[1].toLowerCase();
        if (!VALID_COLOR_TOKENS.has(token)) {
          const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
          diagnostics.push(new vscode.Diagnostic(range, `Token de couleur '${token}' inconnu. Tokens valides : ${Array.from(VALID_COLOR_TOKENS).join(', ')}`, vscode.DiagnosticSeverity.Error));
        }
        continue;
      }
      if (/^icon:\s*[a-zA-Z0-9_\-\.\+]+/.test(line)) continue;
      const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
      diagnostics.push(new vscode.Diagnostic(range, `Propriété de catégorie custom invalide : '${line}'`, vscode.DiagnosticSeverity.Error));
    } else if (currentScope === 'course') {
      if (/^module\s+["'][^"']+["']\s*\{$/.test(line)) {
        braceStack.push({ type: 'module', line: lineNum });
        continue;
      }
      if (/^metadata\s*\{$/.test(line)) {
        braceStack.push({ type: 'metadata', line: lineNum });
        continue;
      }
      const catMatch = line.match(/^category:\s*([a-zA-Z0-9_\-\.\+]+)/);
      if (catMatch) {
        const catVal = catMatch[1].toLowerCase();
        if (!BUILTIN_CATEGORIES.has(catVal) && !declaredCustomCategories.has(catVal)) {
          const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
          diagnostics.push(new vscode.Diagnostic(range, `Catégorie '${catVal}' non déclarée (attendu : intégrée ou déclarée via category custom).`, vscode.DiagnosticSeverity.Error));
        }
        continue;
      }
      const accentMatch = line.match(/^accent:\s*([a-zA-Z0-9_\-\.\+]+)/);
      if (accentMatch) {
        const token = accentMatch[1].toLowerCase();
        if (!VALID_COLOR_TOKENS.has(token)) {
          const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
          diagnostics.push(new vscode.Diagnostic(range, `Token d'accent '${token}' inconnu (repli automatique sur crème).`, vscode.DiagnosticSeverity.Warning));
        }
        continue;
      }
      if (/^(title|description|author|author-key|signature|tdc-version):\s*["']/.test(line) ||
          /^(level|duration|icon):\s*[a-zA-Z0-9_\-\.\+]+/.test(line) ||
          /^keywords:\s*\[.*\]/.test(line)) {
        continue;
      }
      const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
      diagnostics.push(new vscode.Diagnostic(range, `Instruction inconnue dans le bloc course : '${line}'`, vscode.DiagnosticSeverity.Error));
    } else if (currentScope === 'module') {
      if (/^(title|description|markdown|content):\s*["']/.test(line) ||
          /^duration:\s*[a-zA-Z0-9_\-\.]+/.test(line) ||
          /^(content|markdown)\s+"""/.test(line)) {
        continue;
      }
      if (/^quiz\s*\{$/.test(line)) {
        braceStack.push({ type: 'quiz', line: lineNum });
        continue;
      }
      if (/^codeblock\s+["'][^"']+["']\s*\{$/.test(line)) {
        braceStack.push({ type: 'codeblock', line: lineNum });
        continue;
      }
      const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
      diagnostics.push(new vscode.Diagnostic(range, `Instruction inconnue dans le module : '${line}'`, vscode.DiagnosticSeverity.Error));
    } else if (currentScope === 'quiz') {
      if (/^question\s+["'][^"']+["']\s*\{$/.test(line)) {
        braceStack.push({ type: 'question', line: lineNum });
        continue;
      }
      const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
      diagnostics.push(new vscode.Diagnostic(range, `Seules les déclarations 'question "texte" {' sont autorisées dans un quiz.`, vscode.DiagnosticSeverity.Error));
    } else if (currentScope === 'question') {
      if (/^options:\s*\[/.test(line) || /^correctAnswer:\s*\d+/.test(line) || /^explanation:\s*["']/.test(line) || /^\s*["'].*["'],?\s*$/.test(line) || line === ']') {
        continue;
      }
      const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
      diagnostics.push(new vscode.Diagnostic(range, `Propriété de question invalide : '${line}'`, vscode.DiagnosticSeverity.Error));
    } else if (currentScope === 'codeblock') {
      if (/^(content|initialCode|code)\s+"""/.test(line) || /^(language|executable|title):\s*/.test(line) || /^expectedOutput:\s*["']/.test(line)) {
        continue;
      }
      const range = new vscode.Range(lineNum, 0, lineNum, lines[i].length);
      diagnostics.push(new vscode.Diagnostic(range, `Propriété de codeblock invalide : '${line}'`, vscode.DiagnosticSeverity.Error));
    }
  }

  if (inTripleQuote) {
    const range = new vscode.Range(tripleQuoteStartLine, 0, tripleQuoteStartLine, lines[tripleQuoteStartLine].length);
    diagnostics.push(new vscode.Diagnostic(range, 'Bloc de texte multiligne """ non fermé.', vscode.DiagnosticSeverity.Error));
  }

  while (braceStack.length > 0) {
    const unclosed = braceStack.pop();
    const range = new vscode.Range(unclosed.line, 0, unclosed.line, lines[unclosed.line].length);
    diagnostics.push(new vscode.Diagnostic(range, `Bloc '${unclosed.type}' non fermé (accolade '}' manquante).`, vscode.DiagnosticSeverity.Error));
  }

  return diagnostics;
}

/**
 * Fournit la documentation au survol de la souris (Hover)
 */
function createHoverProvider() {
  const HOVER_DOCS = {
    'course': new vscode.MarkdownString('**`course "id" { ... }`**\n\nDéclare le bloc racine d\'un cours TUTODECODE (.tdc).'),
    'module': new vscode.MarkdownString('**`module "id" { ... }`**\n\nDéclare un chapitre ou module de formation avec contenu Markdown et quiz.'),
    'quiz': new vscode.MarkdownString('**`quiz { ... }`**\n\nBloc d\'évaluation interactive contenant une ou plusieurs questions QCM.'),
    'question': new vscode.MarkdownString('**`question "Énoncé" { ... }`**\n\nQuestion interactive avec `options: [...]`, `correctAnswer: 0` et `explanation: "..."`.'),
    'category custom': new vscode.MarkdownString('**`category custom "id" { label: "..." color: mint icon: Rocket }`**\n\nDéclare une catégorie personnalisée auto-contenue pour le partage de cours.'),
    'accent': new vscode.MarkdownString('**`accent: <token>`**\n\nCouleur d\'accent thématique du cours (`creme`, `mint`, `lavande`, `ambre`, `coral`, `sky`, `pink`, `emerald`, `cyan`, `gold`, `linux`).'),
    'signature': new vscode.MarkdownString('**`signature: "<base64>"`**\n\nSignature cryptographique Ed25519 garantissant l\'authenticité de l\'auteur et l\'intégrité du contenu.'),
    'codeblock': new vscode.MarkdownString('**`codeblock "langage" { ... }`**\n\nBloc de code exécutable ou lab interactif terminal.'),
  };

  return {
    provideHover(document, position) {
      const range = document.getWordRangeAtPosition(position);
      if (!range) return null;
      const word = document.getText(range);
      const line = document.lineAt(position.line).text;

      if (line.includes('category custom')) {
        return new vscode.Hover(HOVER_DOCS['category custom']);
      }

      if (HOVER_DOCS[word]) {
        return new vscode.Hover(HOVER_DOCS[word]);
      }
      return null;
    }
  };
}

/**
 * Activation de l'extension VS Code
 * @param {vscode.ExtensionContext} context 
 */
function activate(context) {
  const diagnosticCollection = vscode.languages.createDiagnosticCollection('tdc');
  context.subscriptions.push(diagnosticCollection);

  function refreshDiagnostics(doc) {
    if (doc.languageId === 'tdc' || doc.fileName.endsWith('.tdc')) {
      const diagnostics = validateTDCDocument(doc);
      diagnosticCollection.set(doc.uri, diagnostics);
    }
  }

  // Diagnostics à l'ouverture, modification et sauvegarde
  if (vscode.window.activeTextEditor) {
    refreshDiagnostics(vscode.window.activeTextEditor.document);
  }

  context.subscriptions.push(
    vscode.workspace.onDidOpenTextDocument(refreshDiagnostics),
    vscode.workspace.onDidChangeTextDocument(e => refreshDiagnostics(e.document)),
    vscode.workspace.onDidSaveTextDocument(refreshDiagnostics),
    vscode.workspace.onDidCloseTextDocument(doc => diagnosticCollection.delete(doc.uri))
  );

  // Hover Provider
  context.subscriptions.push(
    vscode.languages.registerHoverProvider({ language: 'tdc' }, createHoverProvider())
  );

  // Commande "Ouvrir dans TDC Studio" (Deep linking via scheme tdcstudio://)
  const openInStudioCmd = vscode.commands.registerCommand('tdc.openInStudio', (uri) => {
    const targetUri = uri || (vscode.window.activeTextEditor ? vscode.window.activeTextEditor.document.uri : null);
    if (!targetUri) {
      vscode.window.showWarningMessage('Aucun fichier .tdc ouvert.');
      return;
    }
    const filePath = targetUri.fsPath;
    const deepLink = `tdcstudio://open?path=${encodeURIComponent(filePath)}`;
    vscode.env.openExternal(vscode.Uri.parse(deepLink));
  });

  context.subscriptions.push(openInStudioCmd);
}

function deactivate() {}

module.exports = {
  activate,
  deactivate,
  validateTDCDocument,
};
