
freeswitch.consoleLog("notice", "[xml_handler] Script loaded successfully.\n");

if (XML_REQUEST["section"] == "directory") then
    freeswitch.consoleLog("notice", "[xml_handler] Handling directory section.\n");
else
    freeswitch.consoleLog("notice", "[xml_handler] Not handling directory section.\n");
end

--set the debug level
debug["params"] = true;
debug["sql"] = true;
debug["xml_request"] = true;
debug["xml_string"] = true;

--show param debug info
if (debug["params"]) then
        freeswitch.consoleLog("notice", "[xml_handler] Params:\n" .. params:serialize() .. "\n");
end

--get the params and set them as variables
local user   = params:getHeader("user");
local user_context = params:getHeader("variable_user_context");
local call_context = params:getHeader("Caller-Context");
local destination_number = params:getHeader("Caller-Destination-Number");
local caller_id_number = params:getHeader("Caller-Caller-ID-Number");

--handle the directory
if (XML_REQUEST["section"] == "directory" and user) then
        local xml = {}
        table.insert(xml, [[<?xml version="1.0" encoding="UTF-8" standalone="no"?>]]);
        table.insert(xml, [[<document type="freeswitch/xml">]]);
        table.insert(xml, [[    <section name="directory">]]);
        table.insert(xml, [[            <domain name="internal">]]);
        table.insert(xml, [[                    <user id="]] .. user .. [[">]]);
        table.insert(xml, [[                    <params>]]);
        table.insert(xml, [[                            <param name="password" value="dummy"/>]]);
        table.insert(xml, [[                            <param name="vm-password" value="0000"/>]]);
        table.insert(xml, [[                    </params>]]);
        table.insert(xml, [[                    <variables>]]);
        table.insert(xml, [[                            <variable name="domain_name" value="internal"/>]]);
        table.insert(xml, [[                            <variable name="caller_id_name" value="]] .. user .. [["/>]]);
        table.insert(xml, [[                            <variable name="caller_id_number" value="]] .. user .. [["/>]]);
        table.insert(xml, [[                            <variable name="user_context" value="internal"/>]]);
        table.insert(xml, [[                            <variable name="record_stereo" value="true"/>]]);
        table.insert(xml, [[                    </variables>]]);
        table.insert(xml, [[                    </user>]]);
        table.insert(xml, [[            </domain>]]);
        table.insert(xml, [[    </section>]]);
        table.insert(xml, [[</document>]]);
        XML_STRING = table.concat(xml, "\n");

        --send the xml to the console
        if (debug["xml_string"]) then
                freeswitch.consoleLog("notice", "[xml_handler] XML_STRING: \n" .. XML_STRING .. "\n");
        end
end

if (debug["xml_request"]) then
        freeswitch.consoleLog("notice", "[xml_handler] Section: " .. XML_REQUEST["section"] .. "\n");
        freeswitch.consoleLog("notice", "[xml_handler] Tag Name: " .. XML_REQUEST["tag_name"] .. "\n");
        freeswitch.consoleLog("notice", "[xml_handler] Key Name: " .. XML_REQUEST["key_name"] .. "\n");
        freeswitch.consoleLog("notice", "[xml_handler] Key Value: " .. XML_REQUEST["key_value"] .. "\n");
end
