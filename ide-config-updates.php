<?php

$DB_USER = getenv('DB_USER');
$DB_PORT = getenv('DB_PORT');


const DATASOURCES_XML = '.idea/dataSources.xml';
const PHP_XML = '.idea/php.xml';
const WORKSPACE_XML = '.idea/workspace.xml';
const MISC_XML = '.idea/misc.xml';

$defaultXml = <<<END
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
</project>

END;


/*******************
 * DATASOURCES XML
 */
$datasourcesXml = loadXml(DATASOURCES_XML, $defaultXml);

$component = getElement($datasourcesXml->documentElement, 'component', 'DataSourceManagerImpl', function (DOMElement $newEl) {
    $newEl->setAttribute('format', 'xml');
    $newEl->setAttribute('multifile-model', 'true');
});

$dataSource = getElement($component, 'data-source', 'neos-local');
replace_child_xml(
    $dataSource, "
    <driver-ref>mysql</driver-ref>
    <synchronize>true</synchronize>
    <jdbc-driver>org.mariadb.jdbc.Driver</jdbc-driver>
    <jdbc-url>jdbc:mysql://127.0.0.1:$DB_PORT</jdbc-url>
    <working-dir>\$ProjectFileDir$</working-dir>
    <user-name>$DB_USER</user-name>
"
);
$datasourcesXml->save(DATASOURCES_XML);

/*******************
 * PHP XML
 */
$phpXml = loadXml(PHP_XML, $defaultXml);
$component = getElement($phpXml->documentElement, 'component', 'PhpInterpreters');
$interpreters = getElement($component, 'interpreters');
$interpreter = getElement($interpreters, 'interpreter', 'PHP devenv.sh');
$interpreter->setAttribute('id', 'EC918378-8957-4AEA-9FA0-CD4A10A174E6');
$interpreter->setAttribute('home', '$PROJECT_DIR$/.devenv/profile/bin/php');
$interpreter->setAttribute('false', 'false');
$interpreter->setAttribute('debugger_id', 'php.debugger.XDebug');
$phpXml->save(PHP_XML);

/*******************
 * WORKSPACE XML
 */
$workspaceXml = loadXml(WORKSPACE_XML, $defaultXml);
$component = getElement($workspaceXml->documentElement, 'component', 'PhpWorkspaceProjectConfiguration');
$component->setAttribute('interpreter_name', 'PHP devenv.sh');
$workspaceXml->save(WORKSPACE_XML);

/*******************
 * MISC XML
 */
$miscXml = loadXml(MISC_XML, $defaultXml);
$component = getElement($miscXml->documentElement, 'component', 'NeosPluginSettings');
replace_child_xml($component, '
    <option name="pluginEnabled" value="true" />
');
$miscXml->save(MISC_XML);


/*******************
 * HELPERS
 */

function loadXml(string $filename, string $defaultXml): DOMDocument
{
    if (!file_exists($filename)) {
        file_put_contents(DATASOURCES_XML, $defaultXml);
    }
    $datasourcesXml = new DOMDocument();
    $datasourcesXml->load($filename);
    return $datasourcesXml;
}

function getElement(DOMElement $context, string $tagName, ?string $nameAttributeValue = null, ?Closure $newElCreator = null): DOMElement
{
    $xpath = new DOMXPath($context->ownerDocument);
    $xpathExpression = './' . $tagName;
    if ($nameAttributeValue) {
        $xpathExpression .= '[@name="' . $nameAttributeValue . '"]';
    }
    $xpathResult = $xpath->query($xpathExpression, $context);
    if ($xpathResult->count() === 0) {
        $newElement = $context->ownerDocument->createElement($tagName);

        if ($nameAttributeValue) {
            $newElement->setAttribute('name', $nameAttributeValue);
        }
        if ($newElCreator) {
            $newElCreator($newElement);
        }
        $context->appendChild($newElement);
        return $newElement;
    } else {
        $el = $xpathResult->item(0);
        assert($el instanceof DOMElement);
        return $el;
    }
}

function replace_child_xml(DOMElement $parent, string $childXml): void
{
    $childXml = (string)$childXml;

    // empty all children
    while ($parent->hasChildNodes()){
        $parent->removeChild($parent->childNodes->item(0));
    }
    $fragment = $parent->ownerDocument->createDocumentFragment();
    $fragment->appendXML($childXml);

    $parent->appendChild($fragment);
}
