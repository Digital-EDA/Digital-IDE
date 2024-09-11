const path = require('path');

async function get_svg_sm(language, code, comment_symbol) {
    if (language === "vhdl") {
        let parser = new Paser_fsm_vhdl(comment_symbol);
        await parser.init();
        let stm = await parser.get_svg_sm(code);
        return stm;
    }
    else if (language === "verilog" || language === "systemverilog") {
        let parser = new Paser_fsm_verilog(comment_symbol);
        await parser.init();
        let stm = await parser.get_svg_sm(code);
        return stm;
    }
}
module.exports = get_svg_sm;

class Ts_base_parser {
    constructor() {
        this.command_end_regex = /@end/gm;
    }

    search_multiple_in_tree(element, matching_title) {
        var arr_match = [];
        function recursive_searchTree(element, matching_title) {
            let type = element.type;
            if (type === matching_title) {
                arr_match.push(element);
            } else if (element !== null) {
                var i;
                var result = null;
                for (i = 0; result === null && i < element.childCount; i++) {
                    result = recursive_searchTree(element.child(i), matching_title);
                }
                return result;
            }
            return null;
        }
        recursive_searchTree(element, matching_title);
        return arr_match;
    }

    search_in_tree(element, matching_title) {
        var match = undefined;
        function recursive_searchTree(element, matching_title) {
            let type = element.type;
            if (type === matching_title) {
                match = element;
            } else if (element !== null) {
                var i;
                var result = null;
                for (i = 0; result === null && i < element.childCount; i++) {
                    result = recursive_searchTree(element.child(i), matching_title);
                    if (result !== null) {
                        break;
                    }
                }
                return result;
            }
            return null;
        }
        recursive_searchTree(element, matching_title);
        return match;
    }

    get_item_multiple_from_childs(p, type) {
        if (p === undefined) {
            return [];
        }
        let items = [];
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === type) {
                let item = cursor.currentNode();
                items.push(item);
            }
        }
        while (cursor.gotoNextSibling() === true);
        return items;
    }

    get_item_from_childs(p, type) {
        if (p === undefined) {
            return undefined;
        }
        let item = undefined;
        let cursor = p.walk();
        let break_p = false;
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === type) {
                item = cursor.currentNode();
                break_p = true;
            }
        }
        while (cursor.gotoNextSibling() === true && break_p === false);
        return item;
    }

    get_item_from_childs_last(p, type) {
        if (p === undefined) {
            return undefined;
        }
        let item = undefined;
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === type) {
                item = cursor.currentNode();
            }
        }
        while (cursor.gotoNextSibling() === true);
        return item;
    }

    parse_doxy(dic, file_type) {
        if (dic.info === undefined) {
            dic.info = {};
        }
        // remove any spaces between linefeed and trim the string
        let desc_root = dic[file_type];
        // always remove carriage return
        desc_root.description = desc_root.description.replace(/\r/gm, "");
        // look for single line commands
        const single_line_regex = /^\s*[@\\](file|date|title|custom_section_begin|custom_section_end)\s.+$/gm;
        // get all matches for single line attributes
        let matches_array = Array.from(desc_root.description.matchAll(single_line_regex));
        // add a new property for the newly found matches
        if (matches_array.length > 0) {
            dic.info = {};
            // append found matches
            for (let index = 0; index < matches_array.length; index++) {
                dic.info[matches_array[index][1]] = matches_array[index][0].replace(/^\s*[@\\](file|date|title|custom_section_begin|custom_section_end)/, "").trim();
            }
            // clean up the description field
            desc_root.description = desc_root.description.replace(single_line_regex, "");
        }
        desc_root.description = desc_root.description.replace(/@copyright/gm, "\n@copyright");
        desc_root.description = desc_root.description.replace(/@author/gm, "\n@author");
        desc_root.description = desc_root.description.replace(/@version/gm, "\n@version");
        desc_root.description = desc_root.description.replace(/@project/gm, "\n@project");
        desc_root.description = desc_root.description.replace(/@brief/gm, "\n@brief");
        desc_root.description = desc_root.description.replace(/@details/gm, "\n@details");

        Doxygen_parser.parse_copyright(dic, desc_root);
        Doxygen_parser.parse_author(dic, desc_root);
        Doxygen_parser.parse_version(dic, desc_root);
        Doxygen_parser.parse_project(dic, desc_root);
        Doxygen_parser.parse_brief(dic, desc_root);
        Doxygen_parser.parse_details(dic, desc_root);
        return dic;
    }

    normalize_description(description) {
        return description;
        let desc_inst = description.replace(/\n\s*\n/g, '<br>');
        desc_inst = desc_inst.replace(/\n/g, '');
        return desc_inst;
    }

    get_comment(comment) {
        if (comment === undefined) {
            return '';
        }
        let txt_comment = comment.slice(2);
        if (this.comment_symbol === '') {
            return txt_comment;
        }
        else if (txt_comment[0] === this.comment_symbol) {
            return txt_comment.slice(1);
        }
        return '';
    }

    get_comment_with_break(comment) {
        if (comment === undefined) {
            return '';
        }
        let txt_comment = comment.slice(2);
        if (this.comment_symbol === '') {
            return txt_comment + '\n';
        }
        else if (txt_comment[0] === this.comment_symbol) {
            return txt_comment.slice(1) + '\n';
        }
        return '';
    }

    set_symbol(symbol) {
        if (symbol === undefined) {
            this.comment_symbol = '';
        }
        else {
            this.comment_symbol = symbol;
        }
    }

    parse_mermaid(dic, file_type) {
        // the command regex
        const mermaid_regex = /^\s*[@\\]mermaid\s*.*[@\\]end/gms;
        // a variable to hold if a mermaid is found and currently opened
        let mermaid_open = false;
        // easy access to the entity description
        let desc_root = dic[file_type];
        // hold the mermaid data
        let mermaid = "";
        // always remove carriage return
        desc_root.description = desc_root.description.replace(/\r/gm, "");
        let match = desc_root.description.match(mermaid_regex)
        if (match !== undefined && match !== null && match.length > 0) {
            desc_root.description = desc_root.description.replace(match[0], "");
            mermaid = match[0].replace(/[@\\]mermaid/gm, "")
            mermaid = mermaid.replace(/[@\\]end/gm, "")
            desc_root.description = desc_root.description.replace("\n\n", "")
            dic[file_type]['description'] = desc_root.description
            dic[file_type]['mermaid'] = mermaid;
        }
        return dic;
    }

    parse_ports_group(dic) {

        const group_regex = /^\s*[@\\]portgroup\s.*$/gm;
        let ports = dic.ports;
        // hold the current group name
        let group_name = "";
        // flag to check if a group is open
        let group_open = false;
        // loop along all ports
        for (let i = 0; i < ports.length; i++) {
            let group = ports[i].description.match(group_regex);
            // look for a new group name
            if (group !== null && group.length > 0) {
                group_open = true;
                ports[i].description = ports[i].description.replace(/^\s*[@\\]portgroup\s/gm, "");
                group_name = ports[i].description.match(/^\s*\w+/)[0];
                ports[i].description = ports[i].description.replace(group_name, "");
            }

            ports[i].group = group_name;
        }
        dic.ports = ports;
        return dic;
    }
    parse_virtual_bus(dic) {
        const virtual_bus_regex_followed = /^\s*[@\\]virtualbus\s.*\n\n/gms;
        const virtual_bus_regex_not_followed = /^\s*[@\\]virtualbus\s.*/
        const virtual_bus_dir_regex = /^\s*[@\\]dir\s/gm;
        const virtual_bus_keep_regex = /^\s*[@\\]keepports\s/gm
        // the base struct is used to reset the virtual_bus_struct when needed
        const virtual_bus_base_struct = {
            "name": "",
            "description": "",
            "direction": "in",
            "keep_ports": false,
            "ports": []
        }
        let ports = dic.ports;
        // hold the indexes that gets removed from the ports list
        let ports_to_remove = [];
        // holds the current virtual bus and gets filled when a new one is encountered
        let virtual_bus_struct = clone(virtual_bus_base_struct);
        // holds all the found virtual buses found so for
        let virtual_bus_array = [];
        // indicates if a virtual bus is found in a port or not
        let virtual_bus_open = false;
        // loop along all ports
        for (let i = 0; i < ports.length; i++) {
            // strip description from \r if present to deal with \n exclusively
            ports[i].description = ports[i].description.replace(/\r/gm, "");

            let virtual_bus = ports[i].description.match(virtual_bus_regex_followed);

            if (virtual_bus === null) {
                virtual_bus = ports[i].description.match(virtual_bus_regex_not_followed);
            }

            if (virtual_bus !== null) {
                if (virtual_bus_open) {
                    // new virtual bus is found and another one was still open, add the old one to the array and clean it
                    virtual_bus_array.push(clone(virtual_bus_struct));
                    virtual_bus_struct = clone(virtual_bus_base_struct);
                }
                let virtual_bus_description = virtual_bus[0];
                // clean the port description from the found virtual bus command
                dic.ports[i].description = ports[i].description.replace(virtual_bus_regex_not_followed, "");
                dic.ports[i].description = ports[i].description.replace(/\n\n/, "");
                dic.ports[i].description = ports[i].description.replace(this.command_end_regex, "");
                // strip virtual bus description from the command part
                virtual_bus_description = virtual_bus_description.replace(/^\s*[@\\]virtualbus\s/, "");
                // construct the name and description of virtual bus
                let virtual_bus_name = virtual_bus_description.match(/^\s*\w+/);
                if (virtual_bus_name !== null) {
                    virtual_bus_name = virtual_bus_description.match(/^\s*\w+/)[0];
                }
                else {
                    virtual_bus_name = "";
                }
                virtual_bus_description = virtual_bus_description.replace(virtual_bus_name, "");
                let virtual_bus_dir = virtual_bus_description.match(virtual_bus_dir_regex);
                // look for optional direction
                if (virtual_bus_dir !== null && virtual_bus_dir.length > 0) {
                    virtual_bus_description = virtual_bus_description.replace(virtual_bus_dir[0], "");
                    virtual_bus_description = virtual_bus_description.replace(/\n\n/, "");
                    virtual_bus_dir = virtual_bus_description.match(/^\s*(out|in)/gm);
                    if (virtual_bus_dir !== null) {
                        virtual_bus_description = virtual_bus_description.replace(virtual_bus_dir[0], "");
                        virtual_bus_struct.direction = virtual_bus_dir[0].trim();
                    } else {
                        virtual_bus_struct.direction = "in";
                    }
                }
                // look for optional flag to keep in signals in table
                let keep_ports = virtual_bus_description.match(virtual_bus_keep_regex);
                // look for optional direction
                if (keep_ports !== null && keep_ports.length > 0) {
                    virtual_bus_description = virtual_bus_description.replace(keep_ports[0], "");
                    virtual_bus_struct.keep_ports = true;
                }
                // update the virtual bus struct with the newly found fields
                virtual_bus_struct.name = virtual_bus_name;
                virtual_bus_struct.description = virtual_bus_description;
                // keep the virtual bus opened to add incoming ports
                virtual_bus_open = true;
            }

            if (virtual_bus_open) {
                // copy the port to the newly created virtualbus
                virtual_bus_struct.ports.push(clone(ports[i]));
                // append current index to be removed
                ports_to_remove.push(clone(i))
            }
            // remove any added \n to description
            dic.ports[i].description = ports[i].description.replace(/\n/, "");

            if (ports[i].description.match(this.command_end_regex) !== null) {
                if (virtual_bus_open) {
                    virtual_bus_open = false;
                    for (let i = 0; i < virtual_bus_struct.ports.length; i++) {
                        virtual_bus_struct.ports[i].description = virtual_bus_struct.ports[i].description.replace(this.command_end_regex, "");
                    }
                    virtual_bus_array.push(clone(virtual_bus_struct));
                    virtual_bus_struct = clone(virtual_bus_base_struct);
                }
            }
        }
        if (virtual_bus_array.length > 0) {
            // append the vbus to the json
            dic.virtual_buses = virtual_bus_array;
            // remove ports from the list
            for (let index = 0; index < ports_to_remove.length; index++) {
                const element = ports_to_remove[index];
                dic.ports.splice(element - index, 1)
            }
            for (let index = 0; index < virtual_bus_array.length; index++) {
                const element = virtual_bus_array[index];
                dic.ports.push({
                    "name": element.name,
                    "type": "virtual_bus",
                    "line": -1,
                    "direction": element.direction,
                    "default_value": "",
                    "description": element.description,
                    "group": ""
                });
            }
        }
        return dic;
    }

}

class Parser_fsm_base extends Ts_base_parser {
    constructor() {
        super();
    }

    check_empty_states_transitions(states) {
        let check = true;
        for (let i = 0; i < states.length; ++i) {
            if (states[i].transitions.length !== 0) {
                check = false;
            }
        }
        return check;
    }

    check_stm(stm) {
        let check = false;
        let states = stm.states;
        for (let i = 0; i < states.length; ++i) {
            let transitions = states[i].transitions;
            if (transitions.length > 0) {
                return true;
            }
        }
        return check;
    }

    json_to_svg(stm_json) {
        let stmcat = this.get_smcat(stm_json);
        const smcat = require("./state-machine-cat");
        let svg;
        try {
            console.error = function () { };
            svg = smcat.render(stmcat, { outputType: "svg" });
        }
        // eslint-disable-next-line no-empty
        catch (e) { }
        return svg;
    }

    get_smcat(stm_json) {
        let sm_states = '';
        let sm_transitions = '';

        let states = stm_json.states;
        let state_names = [];
        for (let i = 0; i < states.length; ++i) {
            if (states[i].transitions.length === 0) {
                state_names.push(states[i].name);
            }
        }
        let emptys = [];
        for (let i = 0; i < state_names.length; ++i) {
            let empty = true;
            for (let j = 0; j < states.length; ++j) {
                for (let m = 0; m < states[j].transitions.length; ++m) {
                    if (states[j].transitions[m].destination === state_names[i]) {
                        empty = false;
                    }
                }
            }
            if (empty === true) {
                emptys.push(state_names[i]);
            }
        }

        let gosth = [];
        state_names = [];
        for (let i = 0; i < states.length; ++i) {
            state_names.push(states[i].name);
        }
        for (let j = 0; j < states.length; ++j) {
            for (let m = 0; m < states[j].transitions.length; ++m) {
                if (state_names.includes(states[j].transitions[m].destination) === false) {
                    let element = { 'name': states[j].transitions[m].destination, 'transitions': [] };
                    stm_json.states.push(element);
                    gosth.push(states[j].transitions[m].destination);
                }
            }
        }
        let num_states = stm_json.states.length;
        stm_json.states.forEach(function (i_state, i) {
            let transitions = i_state.transitions;
            let state_name = i_state.name;
            if (emptys.includes(state_name) === true || gosth.includes(state_name) === true) {
                sm_states += `${state_name} [color="red"]`;
            }
            else {
                sm_states += `${state_name}`;
            }
            if (i !== num_states - 1) {
                sm_states += ',';
            }
            else {
                sm_states += ';\n';
            }
            if (gosth.includes(state_name) !== true) {
                transitions.forEach(function (i_transition, j) {
                    if (gosth.includes(i_transition.destination) === true) {
                        sm_transitions +=
                            `${state_name} => ${i_transition.destination} [color="red"] : ${i_transition.condition};\n`;
                    }
                    else {
                        sm_transitions += `${state_name} => ${i_transition.destination} : ${i_transition.condition};\n`;
                    }
                });
            }
        });
        let str_stm = stm_json.state_variable_name + "{\n" + sm_states + sm_transitions + "\n};";
        return str_stm;
    }

    only_unique(value, index, self) {
        return self.indexOf(value) === index;
    }

    get_comment(comment) {
        if (comment === undefined) {
            return '';
        }
        let txt_comment = comment.slice(2);
        if (this.comment_symbol === '') {
            return txt_comment + '\n';
        }
        else if (txt_comment[0] === this.comment_symbol) {
            return txt_comment.slice(1).trim() + '\n';
        }
        return '';
    }

    set_symbol(symbol) {
        if (symbol === undefined) {
            this.comment_symbol = '';
        }
        else {
            this.comment_symbol = symbol;
        }
    }

}

class Paser_fsm_verilog extends Parser_fsm_base {
    constructor(comment_symbol, parser) {
        super();
        this.set_symbol(comment_symbol);
        if (parser !== undefined) {
            this.parser = parser;
            this.loaded_wasm = true;
        }
    }

    set_comment_symbol(comment_symbol) {
        this.set_symbol(comment_symbol);
    }

    async init() {
        if (this.loaded_wasm !== true) {
            try {
                const Parser = require('./tree-sitter');
                await Parser.init();
                this.parser = new Parser();
                let Lang = await Parser.Language.load(path.join(
                    path.dirname(__dirname), 
                    path.sep + "resources" + 
                    path.sep + "tree-sitter" + 
                    path.sep + "tree-sitter-verilog.wasm"));
                this.parser.setLanguage(Lang);
                this.loaded_wasm = true;
            }
            catch (e) { }
        }
    }

    async get_svg_sm(code, comment_symbol) {
        this.set_symbol(comment_symbol);
        let process;
        try {
            const tree = this.parser.parse(code);
            process = this.get_process(tree);
        }
        catch (e) {
            return { 'svg': [], 'stm': [] };
        }
        let stm = [];
        let svg = [];
        for (let i = 0; i < process.length; ++i) {
            let states;
            try {
                states = this.get_process_info(process[i]);
            }
            catch (e) {
                states = undefined;
            }
            if (states !== undefined) {
                for (let j = 0; j < states.length; ++j) {
                    if (this.check_stm(states[j]) === true) {
                        stm.push(states[j]);
                        let svg_tmp = this.json_to_svg(states[j]);
                        let stm_tmp = {
                            'svg': svg_tmp,
                            'description': states[j].description
                        };
                        svg.push(stm_tmp);
                    }
                }
            }
        }
        return { 'svg': svg, 'stm': stm };
    }

    get_process(tree) {
        let process_array = [];
        let arch_body = this.get_architecture_body(tree);
        let cursor = arch_body.walk();
        let comments = '';
        // Process
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'module_or_generate_item') {
                cursor.gotoFirstChild();
                do {
                    if (cursor.nodeType === 'always_construct') {
                        let process = {
                            'code': this.get_deep_process(cursor.currentNode()),
                            'comments': comments.trim()
                        };
                        process_array.push(process);
                        comments = '';
                    }
                    else {
                        comments = '';
                    }
                }
                while (cursor.gotoNextSibling() !== false);
                cursor.gotoParent();
            }
            else if (cursor.nodeType === 'comment') {
                comments += this.get_comment(cursor.nodeText);
            }
            else {
                comments = '';
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return process_array;
    }

    get_deep_process(p) {
        let statement = this.get_item_from_childs(p, 'statement');
        let statement_item = this.get_item_from_childs(statement, 'statement_item');
        let procedural_timing_control_statement =
            this.get_item_from_childs(statement_item, 'procedural_timing_control_statement');
        if (procedural_timing_control_statement === undefined) {
            let seq_block = this.get_item_from_childs(statement_item, 'seq_block');
            return seq_block;
        }
        let statement_or_null = this.get_item_from_childs(procedural_timing_control_statement, 'statement_or_null');
        let statement_2 = this.get_item_from_childs(statement_or_null, 'statement');
        let statement_item_2 = this.get_item_from_childs(statement_2, 'statement_item');
        let seq_block = this.get_item_from_childs(statement_item_2, 'seq_block');
        if (seq_block === undefined) {
            let cond_statement = this.get_item_from_childs(statement_item_2, 'conditional_statement');
            return cond_statement;
        }

        return seq_block;
    }

    get_architecture_body(p) {
        let break_p = false;
        let arch_body = undefined;
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'module_declaration') {
                arch_body = cursor.currentNode();
                break_p = true;
            }
        }
        while (cursor.gotoNextSibling() === true && break_p === false);
        return arch_body;
    }

    get_process_info(proc) {
        let stms = [];

        let p = proc.code;
        let name = this.get_process_label(p);
        let case_statements = this.get_case_process(p);
        for (let i = 0; i < case_statements.length; ++i) {
            let description = proc.comments;
            let p_info = {
                'description': description.replace('fsm_extract', ''),
                'name': '',
                'state_variable_name': '',
                'states': []
            };
            p_info.name = name;
            if (case_statements !== undefined && case_statements.length !== 0) {
                p_info.state_variable_name = this.get_state_variable_name(case_statements[i]);
                p_info.states = this.get_states(case_statements[i], p_info.state_variable_name);
                let check = this.check_empty_states_transitions(p_info.states);
                if (check === true) {
                    let result = this.force_case_stm(case_statements[i]);
                    p_info.state_variable_name = result.variable_name;
                    p_info.states = result.states;
                }
                stms.push(p_info);
            }
        }
        return stms;
    }

    //////////////////////////////////////////////////////////////////////////////
    // Force
    //////////////////////////////////////////////////////////////////////////////
    force_case_stm(p) {
        let state_names = this.get_state_names_from_case(p);
        let state_name_candidate = this.search_state_variable_candidates(p, state_names);
        let states = this.get_states(p, state_name_candidate);
        return { 'variable_name': state_name_candidate, 'states': states };
    }

    get_state_names_from_case(p) {
        let state_names = [];
        let state_names_case = this.search_multiple_in_tree(p, 'case_item_expression');
        for (let i = 0; i < state_names_case.length; ++i) {
            state_names.push(state_names_case[i].text);
        }
        return state_names;
    }

    search_state_variable_candidates(p, state_names) {
        let candidates = [];
        let signals = this.search_multiple_in_tree(p, 'blocking_assignment');
        for (let i = 0; i < signals.length; ++i) {
            let rigth = this.get_rigth_simple_waveform_assignment(signals[i]);
            if (rigth !== undefined) {
                let left = this.get_left_simple_waveform_assignment(signals[i]);
                if (state_names.includes(rigth) === true) {
                    candidates.push(left);
                }
            }
        }

        let variables = this.search_multiple_in_tree(p, 'nonblocking_assignment');
        for (let i = 0; i < variables.length; ++i) {
            let rigth = this.get_rigth_simple_variable_assignment(variables[i]);
            if (rigth !== undefined) {
                let left = this.get_rigth_simple_variable_assignment(variables[i]);
                if (state_names.includes(rigth) === true) {
                    candidates.push(left);
                }
            }
        }
        let unique = this.mode(candidates);
        return unique;
    }

    mode(array) {
        if (array.length == 0)
            return null;
        var mode_map = {};
        var max_el = array[0], max_count = 1;
        for (var i = 0; i < array.length; i++) {
            var el = array[i];
            if (mode_map[el] == null)
                mode_map[el] = 1;
            else
                mode_map[el]++;
            if (mode_map[el] > max_count) {
                max_el = el;
                max_count = mode_map[el];
            }
        }
        return max_el;
    }
    //////////////////////////////////////////////////////////////////////////////

    get_states(p, state_variable_name) {
        let case_items = this.get_item_multiple_from_childs(p, 'case_item');
        let case_state = [];
        for (let i = 0; i < case_items.length; ++i) {
            let state = {
                'name': '',
                'transitions': [],
                'start_position': [],
                'end_position': []
            };
            let result = this.get_item_from_childs(case_items[i], 'case_item_expression');
            if (result !== undefined && result.text !== 'default') {
                state.name = result.text;
                state.start_position = [result.startPosition.row, result.startPosition.column];
                state.end_position = [result.endPosition.row, result.endPosition.column];
                state.transitions = this.get_transitions(case_items[i], state_variable_name);

                case_state.push(state);
            }
        }
        return case_state;
    }

    get_transitions(p, state_variable_name, metacondition) {
        let assign_transitions = [];
        let if_transitions = [];
        let last_transitions = [];
        let transitions = [];
        let skip = false;
        let last = 0;

        let statement_or_null;
        if (p.type !== 'statement_or_null') {
            statement_or_null = this.get_item_from_childs(p, 'statement_or_null');
        }
        else {
            statement_or_null = p.walk().currentNode();
        }
        let statement = this.get_item_from_childs(statement_or_null, 'statement');
        let statement_item = this.get_item_from_childs(statement, 'statement_item');
        let seq_block = this.get_item_from_childs(statement_item, 'seq_block');
        let itera_item = [];
        if (seq_block === undefined) {
            itera_item = [statement_item];
            skip = true;
        }
        else {
            itera_item = this.get_item_multiple_from_childs(seq_block, 'statement_or_null');
        }
        for (let i = 0; i < itera_item.length; ++i) {
            let statement_item_2 = itera_item[i];
            if (skip === false) {
                let statement_2 = this.get_item_from_childs(itera_item[i], 'statement');
                statement_item_2 = this.get_item_from_childs(statement_2, 'statement_item');
            }
            //Search if
            let type;
            let block;
            let if_statement = this.get_item_from_childs(statement_item_2, 'conditional_statement');
            if (if_statement === undefined) {
                //Search assignment
                let assign_statement = this.get_item_from_childs(statement_item_2, 'blocking_assignment');
                if (assign_statement !== undefined) {
                    type = 'simple_waveform_assignment';
                    block = assign_statement;
                }
                else {
                    let nonassign_statement = this.get_item_from_childs(statement_item_2, 'nonblocking_assignment');
                    if (nonassign_statement !== undefined) {
                        type = 'simple_waveform_assignment';
                        block = nonassign_statement;
                    }
                }
            }
            else {
                type = 'if_statement';
                block = if_statement;
            }

            if (type === 'if_statement') {
                let tmp_transitions = this.get_if_transitions(block, state_variable_name, metacondition);
                if_transitions = if_transitions.concat(tmp_transitions);
                last = 0;
            }
            else if (type === 'simple_waveform_assignment') {
                let tmp_transitions = this.get_assignament_transitions(block, state_variable_name, metacondition);
                if (tmp_transitions.length !== 0 && tmp_transitions !== undefined) {
                    assign_transitions = tmp_transitions;
                    last_transitions = tmp_transitions;
                    last = 1;
                }
            }
        }

        if (last === 1) {
            transitions = last_transitions;
        }
        else {
            transitions = if_transitions.concat(assign_transitions);
        }
        return transitions;
    }

    get_if_transitions(p, state_variable_name, metacondition) {
        let transitions = [];
        let ifs = this.get_if_elsif_else(p);
        //Set else condition
        let conditions = [];
        let else_condition = '';
        for (let i = 0; i < ifs.length; ++i) {
            let condition = ifs[i].condition;
            if (condition !== '' && conditions.includes(condition) === false) {
                else_condition += `not (${condition})\n`;
            }
            else {
                let tmp_condition = else_condition.slice(0, -1);
                //Remove duplicate conditions
                let current_conditions = tmp_condition.split('\n');
                let unique = current_conditions.filter(this.only_unique);
                let condition_tmp = '';
                for (let i = 0; i < unique.length - 1; ++i) {
                    condition_tmp += unique[i] + '\n';
                }
                condition_tmp += unique[unique.length - 1] + '\n';
                condition = condition_tmp;
                ifs[i].condition = condition;
            }
            conditions.push(condition);
        }

        for (let i = 0; i < ifs.length; ++i) {
            let transition = this.get_transition(ifs[i], state_variable_name, metacondition);
            if (transition !== undefined) {
                transitions = transitions.concat(transition);
            }
        }
        return transitions;
    }

    get_if_elsif_else(p) {
        let ifs = [];
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'else') {
                let break_p = false;
                while (break_p === false && cursor.gotoNextSibling() !== false) {
                    if (cursor.nodeType === 'statement_or_null') {
                        let item = this.get_item_from_childs(cursor.currentNode(), 'statement');
                        let statement_item = this.get_item_from_childs(item, 'statement_item');

                        let block_item = this.get_item_from_childs(statement_item, 'seq_block');
                        if (block_item !== undefined) {
                            item = this.get_item_from_childs(block_item, 'statement_or_null');
                            item = this.get_item_from_childs(item, 'statement');
                            statement_item = this.get_item_from_childs(item, 'statement_item');
                        }
                        item = this.get_item_from_childs(statement_item, 'conditional_statement');
                        if (item !== undefined) {
                            let tmp_ifs = this.get_if_elsif_else(item);
                            ifs = ifs.concat(tmp_ifs);
                        }
                        else {
                            let if_item_else = {
                                'condition': '',
                                'code': '',
                                'start_position': '',
                                'end_position': ''
                            };

                            let blocking_assignment = this.get_item_from_childs(statement_item, 'blocking_assignment');
                            if (blocking_assignment !== undefined) {
                                if (block_item !== undefined) {
                                    if_item_else.code = block_item;
                                    // if_item_else.start_position = start_position;
                                    // if_item_else.end_position = end_position;
                                }
                                else {
                                    if_item_else.code = statement_item;
                                    // if_item_else.start_position = start_position;
                                    // if_item_else.end_position = end_position;
                                }
                                ifs.push(if_item_else);
                            }
                            else {
                                let nonblocking_assignment = this.get_item_from_childs(statement_item, 'nonblocking_assignment');
                                if (nonblocking_assignment !== undefined) {
                                    if (block_item !== undefined) {
                                        if_item_else.code = block_item;
                                        // if_item_else.start_position = start_position;
                                        // if_item_else.end_position = end_position;
                                    }
                                    else {
                                        if_item_else.code = statement_item;
                                        // if_item_else.start_position = start_position;
                                        // if_item_else.end_position = end_position;
                                    }
                                    ifs.push(if_item_else);
                                }
                            }
                        }
                    }
                }
            }
            else if (cursor.nodeType === 'if') {
                let break_p = false;
                let if_item = {
                    'condition': '',
                    'code': ''
                };
                while (break_p === false && cursor.gotoNextSibling() !== false) {
                    if (cursor.nodeType === 'cond_predicate') {
                        let item = this.get_item_from_childs(cursor.currentNode(), 'expression_or_cond_pattern');
                        if (item !== undefined) {
                            if_item.condition = item.text;
                            if_item.start_position = item.startPosition;
                            if_item.end_position = item.endPosition;
                        }
                    }
                    else if (cursor.nodeType === 'statement_or_null') {
                        let item = this.get_item_from_childs(cursor.currentNode(), 'statement');
                        item = this.get_item_from_childs(item, 'statement_item');
                        if (this.get_item_from_childs(item, 'seq_block') !== undefined) {
                            item = this.get_item_from_childs(item, 'seq_block');
                            if_item.start_position = item.startPosition;
                            if_item.end_position = item.endPosition;
                            // item = this.get_item_from_childs(item, 'statement_or_null');
                            // item = this.get_item_from_childs(item, 'statement');
                            // item = this.get_item_from_childs(item, 'statement_item');
                        }
                        if_item.code = item;
                        break_p = true;
                        ifs.push(if_item);
                    }
                }
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return ifs;
    }

    get_assignament_transitions(p, state_variable_name, metacondition) {
        let transitions = [];

        let tmp_destination = this.check_get_simple_waveform_assignment(p, state_variable_name);
        if (tmp_destination !== undefined) {
            let s_position = p.startPosition;
            let e_position = p.endPosition;
            let start_position = [s_position.row, e_position.column - 1];
            let end_position = [e_position.row, e_position.column];

            let condition = '';
            if (metacondition !== '' && metacondition !== undefined) {
                condition = metacondition;
            }

            let destination = tmp_destination;
            let transition = {
                'condition': condition,
                'destination': destination,
                'start_position': start_position,
                'end_position': end_position
            };
            transitions.push(transition);
        }
        return transitions;
    }

    get_transition(p, state_variable_name, metacondition) {
        let condition = p.condition;
        let tmp_start_position = p.start_position;
        let tmp_end_position = p.end_position;

        let start_position = [tmp_start_position.row, tmp_start_position.column];
        let end_position = [tmp_end_position.row, tmp_end_position.column];
        let transitions = this.get_transitions_in_if(p.code, state_variable_name,
            condition, start_position, end_position, metacondition);
        return transitions;
    }

    get_start_position_array(p) {
        let tmp_position = p.code.startPosition;
        return tmp_position;
    }

    get_end_position_array(p) {
        let tmp_position = p.code.endPosition;
        return tmp_position;
    }

    get_transitions_in_if(p, state_variable_name, condition, start_position, end_position, metacondition) {
        let last = 0;
        let last_transitions = [];
        //if transitions
        let if_transitions = [];
        //assign transitions
        let assign_transitions = [];
        let transitions = [];
        let destination = undefined;
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'blocking_assignment' || cursor.nodeType === 'nonblocking_assignment') {
                let tmp_destination = this.check_get_simple_waveform_assignment(cursor.currentNode(), state_variable_name);
                if (tmp_destination !== undefined) {
                    destination = tmp_destination;
                    if (condition !== undefined && destination !== undefined) {
                        let transition = {
                            'condition': '',
                            'destination': '',
                            'start_position': start_position,
                            'end_position': end_position
                        };
                        if (metacondition !== undefined && metacondition !== '') {
                            condition += `\n${metacondition}`;
                            let current_conditions = condition.split('\n');
                            let unique = current_conditions.filter(this.only_unique);
                            let condition_tmp = '';
                            for (let i = 0; i < unique.length - 1; ++i) {
                                condition_tmp += unique[i] + '\n';
                            }
                            condition_tmp += unique[unique.length - 1] + '\n';
                            condition = condition_tmp;
                        }

                        transition.condition = condition;
                        transition.destination = destination;
                        last = 1;
                        assign_transitions = [transition];
                        last_transitions = [transition];
                    }
                }
            }
            else if (cursor.nodeType === 'simple_variable_assignment') {
                let tmp_destination = this.check_get_simple_variable_assignment(cursor.currentNode(), state_variable_name);
                if (tmp_destination !== undefined) {
                    destination = tmp_destination;
                    if (condition !== undefined && destination !== undefined) {
                        let transition = {
                            'condition': '',
                            'destination': '',
                            'start_position': start_position,
                            'end_position': end_position
                        };
                        if (metacondition !== undefined && metacondition !== '') {
                            condition += `\n${metacondition}`;
                            let current_conditions = condition.split('\n');
                            let unique = current_conditions.filter(this.only_unique);
                            let condition_tmp = '';
                            for (let i = 0; i < unique.length - 1; ++i) {
                                condition_tmp += unique[i] + '\n';
                            }
                            condition_tmp += unique[unique.length - 1] + '\n';
                            condition = condition_tmp;
                        }

                        transition.condition = condition;
                        transition.destination = destination;
                        last = 1;
                        assign_transitions = [transition];
                        last_transitions = [transition];
                    }
                }
            }
            else if (cursor.nodeType === 'conditional_statement') {
                last = 0;
                let if_transitions_tmp = this.get_if_transitions(cursor.currentNode(), state_variable_name, condition);
                if_transitions = if_transitions.concat(if_transitions_tmp);
            }
            else if (cursor.nodeType === 'statement_or_null') {
                last = 0;

                //check assignement
                let item = this.get_item_from_childs(cursor.currentNode(), 'statement');
                item = this.get_item_from_childs(item, 'statement_item');
                let item_0 = this.get_item_from_childs(item, 'blocking_assignment');
                let item_1 = this.get_item_from_childs(item, 'nonblocking_assignment');
                let if_item = true;
                if (item_0 !== undefined || item_1 !== undefined) {
                    if_item = false;
                }
                if (metacondition !== undefined && metacondition !== '') {
                    condition += `\n${metacondition}`;
                    let current_conditions = condition.split('\n');
                    let unique = current_conditions.filter(this.only_unique);
                    let condition_tmp = '';
                    for (let i = 0; i < unique.length - 1; ++i) {
                        condition_tmp += unique[i] + '\n';
                    }
                    condition_tmp += unique[unique.length - 1] + '\n';
                    condition = condition_tmp;
                }

                let if_transitions_tmp = [];
                //check block if
                let item_block_if = this.get_item_from_childs(item, 'conditional_statement');
                if (item_block_if === undefined) {
                    if_transitions_tmp = this.get_transitions(cursor.currentNode(), state_variable_name, condition);
                }
                else {
                    if_transitions_tmp = this.get_if_transitions(item_block_if, state_variable_name, condition);
                }

                if (if_item === false) {
                    if (if_transitions_tmp.length !== 0) {
                        assign_transitions = if_transitions_tmp;
                        last_transitions = if_transitions_tmp;
                    }
                }
                else {
                    if_transitions = if_transitions.concat(if_transitions_tmp);
                }

            }
        }
        while (cursor.gotoNextSibling() !== false);


        if (last !== 0) {
            transitions = last_transitions;
        }
        else {
            transitions = if_transitions.concat(assign_transitions);
        }
        return transitions;
    }

    check_get_simple_waveform_assignment(p, state_variable_name) {
        let destination = undefined;
        let left = this.get_left_simple_waveform_assignment(p);
        if (left === state_variable_name) {
            destination = this.get_rigth_simple_waveform_assignment(p);
        }
        return destination;
    }

    check_get_simple_variable_assignment(p, state_variable_name) {
        let destination = undefined;
        let left = this.get_left_simple_waveform_assignment(p);
        if (left === state_variable_name) {
            destination = this.get_rigth_simple_variable_assignment(p);
        }
        return destination;
    }

    get_left_simple_waveform_assignment(p) {
        let left = '';
        let item = this.get_item_from_childs(p, 'operator_assignment');
        item = this.get_item_from_childs(item, 'variable_lvalue');
        if (item !== undefined) {
            left = item.text;
        }
        if (left === '') {
            item = this.get_item_from_childs(p, 'variable_lvalue');
            if (item !== undefined) {
                left = item.text;
            }
        }
        return left;
    }

    get_rigth_simple_waveform_assignment(p) {
        let rigth = undefined;
        let item = this.get_item_from_childs(p, 'operator_assignment');
        item = this.get_item_from_childs(item, 'expression');
        if (item !== undefined) {
            rigth = item.text;
        }
        if (rigth === undefined) {
            item = this.get_item_from_childs(p, 'expression');
            if (item !== undefined) {
                rigth = item.text;
            }
        }
        return rigth;
    }

    get_rigth_simple_variable_assignment(p) {
        let rigth = undefined;
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'simple_name') {
                rigth = cursor.nodeText;
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return rigth;
    }

    get_state_variable_name(p) {
        let state_variable_name = undefined;
        let case_expression = this.get_item_from_childs(p, 'case_expression');
        if (case_expression !== undefined) {
            state_variable_name = case_expression.text;
        }
        return state_variable_name;
    }

    get_case_process(p) {
        let case_statement = this.search_multiple_in_tree(p, 'case_statement');
        return case_statement;
    }

    get_process_label(p) {
        let label_txt = '';
        let label = this.get_item_from_childs(p, "block_identifier");
        if (label === undefined) {
            label_txt = ''
        }
        else {
            label_txt = label.text;
        }
        return label_txt;
    }
}

class Paser_fsm_vhdl extends Parser_fsm_base {
    constructor(comment_symbol, parser) {
        super();
        this.set_symbol(comment_symbol);
        if (parser !== undefined) {
            this.parser = parser;
            this.loaded_wasm = true;
        }
    }

    async init() {
        if (this.loaded_wasm !== true) {
            try {
                const Parser = require('./tree-sitter');
                await Parser.init();
                this.parser = new Parser();
                let Lang = await
                    Parser.Language.load(path.join(
                        path.dirname(__dirname), 
                        path.sep + "resources" + 
                        path.sep + "tree-sitter" + 
                        path.sep + "tree-sitter-vhdl.wasm"));
                this.parser.setLanguage(Lang);
                this.loaded_wasm = true;
            } catch (e) { }
        }
    }

    set_comment_symbol(comment_symbol) {
        this.set_symbol(comment_symbol);
    }

    async get_svg_sm(code, comment_symbol) {
        this.set_comment_symbol(comment_symbol);

        let process;
        let tree;
        try {
            tree = this.parser.parse(code);
            process = this.get_process(tree);
        } catch (e) {
            return { 'svg': [], 'stm': [] };
        }
        let stm = [];
        let svg = [];
        for (let i = 0; i < process.length; ++i) {
            let states;
            try {
                states = this.get_process_info(process[i]);
            } catch (e) {
                states = undefined;
            }
            if (states !== undefined) {
                for (let j = 0; j < states.length; ++j) {
                    if (this.check_stm(states[j]) === true) {
                        stm.push(states[j]);
                        let svg_tmp = this.json_to_svg(states[j]);
                        let stm_tmp = {
                            'svg': svg_tmp,
                            'description': states[j].description
                        };
                        svg.push(stm_tmp);
                    }
                }
            }
        }
        return { 'svg': svg, 'stm': stm };
    }

    get_process(tree) {
        let process_array = [];
        let arch_body = this.get_architecture_body(tree);
        let cursor = arch_body.walk();
        let comments = '';
        // Process
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'process_statement') {
                let process = {
                    'code': cursor.currentNode(),
                    'comments': comments
                };
                process_array.push(process);
                comments = '';
            } else if (cursor.nodeType === 'comment') {
                comments += this.get_comment(cursor.nodeText);
            } else {
                comments = '';
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return process_array;
    }

    get_architecture_body(p) {
        let cursor = p.walk();
        let item = this.get_item_multiple_from_childs(cursor.currentNode(), 'design_unit');
        if (item.length === 2) {
            item = this.get_item_from_childs(item[1], 'architecture_body');
            item = this.get_item_from_childs(item, 'concurrent_statement_part');
            return item;
        } else {
            return undefined;
        }
    }

    get_process_info(proc) {
        let stms = [];

        let p = proc.code;
        let name = this.get_process_label(p);
        let case_statements = this.get_case_process(p);
        for (let i = 0; i < case_statements.length; ++i) {
            let description = proc.comments;
            let p_info = {
                'description': description.replace('fsm_extract', ''),
                'name': '',
                'state_variable_name': '',
                'states': []
            };
            p_info.name = name;
            if (case_statements !== undefined && case_statements.length !== 0) {
                p_info.state_variable_name = this.get_state_variable_name(case_statements[i]);
                p_info.states = this.get_states(case_statements[i], p_info.state_variable_name);
                let check = this.check_empty_states_transitions(p_info.states);
                if (check === true) {
                    let result = this.force_case_stm(case_statements[i]);
                    p_info.state_variable_name = result.variable_name;
                    p_info.states = result.states;
                }
                stms.push(p_info);
            }
        }
        return stms;
    }

    force_case_stm(p) {
        let state_names = this.get_state_names_from_case(p).map(v => v.toLowerCase());
        let state_name_candidate = this.search_state_variable_candidates(p, state_names);
        let states = this.get_states(p, state_name_candidate);
        return { 'variable_name': state_name_candidate, 'states': states };
    }

    search_state_variable_candidates(p, state_names) {
        let candidates = [];
        let signals = this.search_multiple_in_tree(p, 'simple_waveform_assignment');
        for (let i = 0; i < signals.length; ++i) {
            let rigth = this.get_item_from_childs(signals[i], 'waveforms');
            if (rigth !== undefined) {
                let rigth_text = rigth.text.toLowerCase();
                let left = this.get_left_simple_waveform_assignment(signals[i]);
                if (state_names.includes(rigth_text) === true) {
                    candidates.push(left);
                }
            }
        }

        let variables = this.search_multiple_in_tree(p, 'simple_variable_assignment');
        for (let i = 0; i < variables.length; ++i) {
            let rigth = this.get_item_from_childs(variables[i], 'waveforms');
            if (rigth === undefined) {
                rigth = this.get_item_from_childs_last(variables[i], 'simple_name');
            }
            if (rigth !== undefined) {
                let rigth_text = rigth.text.toLowerCase();
                let left = this.get_left_simple_waveform_assignment(variables[i]);
                if (state_names.includes(rigth_text) === true) {
                    candidates.push(left);
                }
            }
        }
        let unique = this.mode(candidates);
        return unique;
    }

    mode(array) {
        if (array.length === 0) {
            return null;
        }
        var mode_map = {};
        var max_el = array[0],
            max_count = 1;
        for (var i = 0; i < array.length; i++) {
            var el = array[i];
            if (mode_map[el] == null) {
                mode_map[el] = 1;
            } else {
                mode_map[el]++;
            }
            if (mode_map[el] > max_count) {
                max_el = el;
                max_count = mode_map[el];
            }
        }
        return max_el;
    }

    get_state_names_from_case(p) {
        let state_names = [];
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'case_statement_alternative') {
                let result = this.get_state_name(cursor.currentNode());
                let name = result.state_name;
                state_names.push(name);
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return state_names;
    }



    get_states(p, state_variable_name) {
        let case_state = [];
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'case_statement_alternative') {
                let state = {
                    'name': '',
                    'transitions': [],
                    'start_position': [],
                    'end_position': []
                };
                let result = this.get_state_name(cursor.currentNode());
                let name = result.state_name;
                if (name !== undefined && name.toLocaleLowerCase() !== 'others') {
                    state.name = result.state_name;
                    state.start_position = result.start_position;
                    state.end_position = result.end_position;
                    state.transitions = this.get_transitions(cursor.currentNode(), state_variable_name);

                    case_state.push(state);
                }
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return case_state;
    }

    get_transitions(p, state_variable_name) {
        let transitions = [];
        let cursor = p.walk();
        let last = 0;
        let last_transitions = [];
        //if transitions
        let if_transitions = [];
        //assign transitions
        let assign_transitions = [];

        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'sequence_of_statements') {
                cursor.gotoFirstChild();
                do {
                    if (cursor.nodeType === 'if_statement') {
                        let tmp_transitions = this.get_if_transitions(cursor.currentNode(), state_variable_name);
                        if_transitions = if_transitions.concat(tmp_transitions);
                        last = 0;
                    } else if (cursor.nodeType === 'simple_waveform_assignment') {
                        let tmp_transitions = this.get_assignament_transitions(
                            cursor.currentNode(), state_variable_name);
                        if (tmp_transitions.length !== 0 && tmp_transitions !== undefined) {
                            assign_transitions = tmp_transitions;
                            last_transitions = tmp_transitions;
                            last = 1;
                        }
                    } else if (cursor.nodeType === 'simple_variable_assignment') {
                        let tmp_transitions = this.get_assignament_variable_transitions(
                            cursor.currentNode(), state_variable_name);
                        if (tmp_transitions.length !== 0 && tmp_transitions !== undefined) {
                            assign_transitions = tmp_transitions;
                            last_transitions = tmp_transitions;
                            last = 1;
                        }
                    } else if (cursor.nodeType === 'case_statement') {
                        let tmp_transitions = this.get_case_transitions(cursor.currentNode(), state_variable_name);
                        if_transitions = if_transitions.concat(tmp_transitions);
                        last = 0;
                    }
                }
                while (cursor.gotoNextSibling() !== false);
            }
        }
        while (cursor.gotoNextSibling() !== false);
        if (last === 1) {
            transitions = last_transitions;
        } else {
            transitions = if_transitions.concat(assign_transitions);
        }
        return transitions;
    }

    get_if_transitions(p, state_variable_name, metacondition) {
        let transitions = [];
        let cursor = p.walk();
        let else_conditions = '';
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'elsif' || cursor.nodeType === 'if') {
                let if_condition = this.get_condition(cursor.currentNode());
                if (if_condition !== undefined) {
                    else_conditions += `not (${if_condition.condition})\n`;
                }
                let transition = this.get_transition(cursor.currentNode(), state_variable_name, metacondition);
                if (transition !== undefined) {
                    transitions = transitions.concat(transition);
                }
            } else if (cursor.nodeType === 'else') {
                if (metacondition !== undefined) {
                    else_conditions = metacondition + '\n' + else_conditions;
                }
                let transition = this.get_transition(cursor.currentNode(), state_variable_name, else_conditions);
                if (transition !== undefined) {
                    transitions = transitions.concat(transition);
                }
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return transitions;
    }

    get_case_transitions(p, state_variable_name, metacondition) {
        let transitions = [];
        let cursor = p.walk();
        let else_conditions = '';
        let case_switch = this.get_item_from_childs(cursor.currentNode(), 'simple_name').text;
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'case_statement_alternative') {
                let choice = this.get_item_from_childs(cursor.currentNode(), 'choices');
                let choice_txt = choice.text;
                let if_condition = `${case_switch} = ${choice_txt}`;
                if (choice_txt.toLocaleLowerCase() === 'others') {
                    if_condition = else_conditions;
                } else if (if_condition !== undefined) {
                    else_conditions += `not (${if_condition})\n`;
                }
                let transition = this.get_transition(cursor.currentNode(),
                    state_variable_name, metacondition, if_condition);
                if (transition !== undefined) {
                    transitions = transitions.concat(transition);
                }
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return transitions;
    }

    get_assignament_transitions(p, state_variable_name) {
        let transitions = [];

        let tmp_destination = this.check_get_simple_waveform_assignment(p, state_variable_name);
        if (tmp_destination !== undefined) {
            let s_position = p.startPosition;
            let e_position = p.endPosition;
            let start_position = [s_position.row, e_position.column - 1];
            let end_position = [e_position.row, e_position.column];

            let destination = tmp_destination;
            let transition = {
                'condition': '',
                'destination': destination,
                'start_position': start_position,
                'end_position': end_position
            };
            transitions.push(transition);
        }
        return transitions;
    }

    get_assignament_variable_transitions(p, state_variable_name) {
        let transitions = [];

        let tmp_destination = this.check_get_simple_variable_assignment(p, state_variable_name);
        if (tmp_destination !== undefined) {
            let s_position = p.startPosition;
            let e_position = p.endPosition;
            let start_position = [s_position.row, e_position.column - 1];
            let end_position = [e_position.row, e_position.column];

            let destination = tmp_destination;
            let transition = {
                'condition': '',
                'destination': destination,
                'start_position': start_position,
                'end_position': end_position
            };
            transitions.push(transition);
        }
        return transitions;
    }

    get_transition(p, state_variable_name, metacondition, choice) {
        let result = this.get_condition(p, choice);
        let condition = result.condition;
        let start_position = result.start_position;
        let end_position = result.end_position;
        let transitions = this.get_transitions_in_if(p, state_variable_name,
            condition, start_position, end_position, metacondition);
        return transitions;
    }

    get_transitions_in_if(p, state_variable_name, condition, start_position, end_position, metacondition) {
        let last = 0;
        let last_transitions = [];
        //if transitions
        let if_transitions = [];
        //assign transitions
        let assign_transitions = [];
        let transitions = [];
        let destination = undefined;
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'sequence_of_statements') {
                cursor.gotoFirstChild();
                do {
                    if (cursor.nodeType === 'simple_waveform_assignment') {
                        let tmp_destination = this.check_get_simple_waveform_assignment(
                            cursor.currentNode(), state_variable_name);
                        if (tmp_destination !== undefined) {
                            destination = tmp_destination;
                            if (condition !== undefined && destination !== undefined) {
                                let transition = {
                                    'condition': '',
                                    'destination': '',
                                    'start_position': start_position,
                                    'end_position': end_position
                                };
                                if (metacondition !== undefined && metacondition !== '') {
                                    condition += `\n${metacondition}`;
                                    let current_conditions = condition.split('\n');
                                    let unique = current_conditions.filter(this.only_unique);
                                    let condition_tmp = '';
                                    for (let i = 0; i < unique.length - 1; ++i) {
                                        condition_tmp += unique[i] + '\n';
                                    }
                                    condition_tmp += unique[unique.length - 1] + '\n';
                                    condition = condition_tmp;
                                }
                                transition.condition = condition;
                                transition.destination = destination;
                                last = 1;
                                assign_transitions = [transition];
                                last_transitions = [transition];
                            }
                        }
                    } else if (cursor.nodeType === 'simple_variable_assignment') {
                        let tmp_destination = this.check_get_simple_variable_assignment(
                            cursor.currentNode(), state_variable_name);
                        if (tmp_destination !== undefined) {
                            destination = tmp_destination;
                            if (condition !== undefined && destination !== undefined) {
                                let transition = {
                                    'condition': '',
                                    'destination': '',
                                    'start_position': start_position,
                                    'end_position': end_position
                                };
                                if (metacondition !== undefined && metacondition !== '') {
                                    condition += `\n${metacondition}`;
                                    let current_conditions = condition.split('\n');
                                    let unique = current_conditions.filter(this.only_unique);
                                    let condition_tmp = '';
                                    for (let i = 0; i < unique.length - 1; ++i) {
                                        condition_tmp += unique[i] + '\n';
                                    }
                                    condition_tmp += unique[unique.length - 1] + '\n';
                                    condition = condition_tmp;
                                }
                                transition.condition = condition;
                                transition.destination = destination;
                                last = 1;
                                assign_transitions = [transition];
                                last_transitions = [transition];
                            }
                        }
                    } else if (cursor.nodeType === 'if_statement') {
                        if (metacondition !== undefined && metacondition !== '') {
                            condition += condition + '\n' + metacondition;
                        }
                        last = 0;
                        if_transitions = this.get_if_transitions(cursor.currentNode(), state_variable_name, condition);
                    } else if (cursor.nodeType === 'case_statement') {
                        if (metacondition !== undefined && metacondition !== '') {
                            condition += condition + '\n' + metacondition;
                        }
                        last = 0;
                        if_transitions = this.get_case_transitions(cursor.currentNode(),
                            state_variable_name, condition);
                    }
                }
                while (cursor.gotoNextSibling() !== false);
            }
        }
        while (cursor.gotoNextSibling() !== false);
        if (last !== 0) {
            transitions = last_transitions;
        } else {
            transitions = if_transitions.concat(assign_transitions);
        }
        return transitions;
    }

    check_get_simple_waveform_assignment(p, state_variable_name) {
        let destination = undefined;
        if (state_variable_name === undefined) {
            return destination;
        }
        if (this.get_left_simple_waveform_assignment(p).toLowerCase() === state_variable_name.toLowerCase()) {
            destination = this.get_rigth_simple_waveform_assignment(p);
        }
        return destination;
    }

    check_get_simple_variable_assignment(p, state_variable_name) {
        let destination = undefined;
        if (state_variable_name === undefined) {
            return destination;
        }
        if (this.get_left_simple_waveform_assignment(p).toLowerCase() === state_variable_name.toLowerCase()) {
            destination = this.get_rigth_simple_variable_assignment(p);
        }
        return destination;
    }

    get_left_simple_waveform_assignment(p) {
        let left = 'undefined';
        let cursor = p.walk();
        let break_p = false;
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'simple_name') {
                left = cursor.nodeText;
                break_p = true;
            } else if (cursor.nodeType === 'selected_name') {
                left = cursor.nodeText.split('.');
                left = left[left.length - 1];
                break_p = true;
            }
        }
        while (cursor.gotoNextSibling() !== false && break_p === false);
        return left;
    }

    get_rigth_simple_waveform_assignment(p) {
        let rigth = undefined;
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'waveforms') {
                rigth = cursor.nodeText.split(/(\s)/)[0].trim();
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return rigth;
    }

    get_rigth_simple_variable_assignment(p) {
        let rigth = undefined;
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'simple_name') {
                rigth = cursor.nodeText.split(/(\s)/)[0].trim();
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return rigth;
    }

    get_condition(p, choice) {
        let condition = '';
        let cursor = p.walk();
        let start_position = [];
        let end_position = [];
        let s_position = cursor.startPosition;
        let e_position = cursor.endPosition;
        start_position = [s_position.row, s_position.column];
        end_position = [e_position.row, e_position.column];

        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'relation' || cursor.nodeType === 'logical_expression' ||
                cursor.nodeType === 'parenthesized_expression') {
                if (cursor.nodeType === 'parenthesized_expression') {
                    condition = this.get_relation_of_parenthesized_expression(cursor.currentNode());
                } else {
                    condition = cursor.nodeText;
                }
                s_position = cursor.startPosition;
                e_position = cursor.endPosition;
                start_position = [s_position.row, s_position.column];
                end_position = [e_position.row, e_position.column];
            } else if (cursor.nodeType === 'choices') {
                condition = choice;
                s_position = cursor.startPosition;
                e_position = cursor.endPosition;
                start_position = [s_position.row, s_position.column];
                end_position = [e_position.row, e_position.column];
            }
            if (cursor.nodeType === 'else') {
                s_position = cursor.startPosition;
                e_position = cursor.endPosition;
                start_position = [s_position.row, s_position.column];
                end_position = [e_position.row, e_position.column];
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return {
            'condition': condition,
            'start_position': start_position,
            'end_position': end_position
        };
    }

    get_relation_of_parenthesized_expression(p) {
        let relation = undefined;
        let cursor = p.walk();
        let break_p = false;
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'relation' || cursor.nodeType === 'logical_expression') {
                relation = cursor.nodeText;
                break_p = true;
            }
        }
        while (cursor.gotoNextSibling() !== false && break_p === false);
        return relation;
    }

    get_state_name(p) {
        let state_name = undefined;
        let start_position = [];
        let end_position = [];
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'choices') {
                let s_position = cursor.startPosition;
                let e_position = cursor.endPosition;
                start_position = [s_position.row, s_position.column];
                end_position = [e_position.row, e_position.column];
                state_name = cursor.nodeText;
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return { 'state_name': state_name, 'start_position': start_position, 'end_position': end_position };
    }


    get_state_variable_name(p) {
        let state_variable_name = undefined;
        let cursor = p.walk();
        cursor.gotoFirstChild();
        do {
            if (cursor.nodeType === 'simple_name') {
                state_variable_name = cursor.nodeText;
            } else if (cursor.nodeType === 'parenthesized_expression') {
                state_variable_name = cursor.nodeText.replace('(', '').replace(')', '');
            }
        }
        while (cursor.gotoNextSibling() !== false);
        return state_variable_name;
    }

    get_case_process(p) {
        let case_statement = this.search_multiple_in_tree(p, 'case_statement');
        return case_statement;
    }


    get_process_label(p) {
        let label = '';
        let cursor = p.walk();
        //Process label
        cursor.gotoFirstChild();
        if (cursor.nodeType === 'label') {
            cursor.gotoFirstChild();
            label = cursor.nodeText;
        }
        return label;
    }
}

