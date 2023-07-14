/* eslint-disable @typescript-eslint/naming-convention */
const vscode = acquireVsCodeApi();

// Handle the message inside the webview
window.addEventListener('message', event => {
    const message = event.data; // The JSON data our extension sen
    switch (message.command) {
        case 'update':
            update_graph(message.svg, message.stms);
            break;
        case 'clear':
            clear();
            break;
    }
});

let graph = [];
let div = [];
let stms = [];

function update_graph(svgs, stms_i) {
    stms = stms_i;
    const el = document.querySelector('body');
    // get scroll position in px
    let last_scroll_left = el.scrollLeft;
    let last_scroll_top = el.scrollTop;

    let message = document.getElementById("message");
    message.innerHTML = `#State machines ${svgs.length}`;

    delete_graph();
    if (svgs === undefined) {
        return;
    }
    for (let i = 0; i < svgs.length; ++i) {
        create_graph(svgs[i].svg, `svg_${i}`, i);
    }

    // set scroll position in px
    el.scrollLeft = last_scroll_left;
    el.scrollTop = last_scroll_top;
}

function create_graph(svg, name, index) {
    let embed = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    embed.setAttribute('style', 'width: 100%; height: 720px;');
    embed.setAttribute('type', 'image/svg+xml');
    embed.innerHTML = svg;
    embed.id = name;

    //Add div
    var elem = document.createElement('div');
    elem.style.width = "100%";
    elem.style.heigh = "500px";
    elem.style.border = "1px solid black";
    div.push(elem);

    document.body.appendChild(elem);

    //Add svg
    elem.appendChild(embed);

    let pan_zoom = svgPanZoom(`#${name}`, pan_config);
    pan_zoom.center();
    pan_zoom.resize();

    let countries = embed.childNodes;
    for (let i = 0; i < countries.length; i++) {
        countries[i].addEventListener('click', e => {
            let parent_target = e.target.parentNode;
            let childs = parent_target.childNodes;
            for (let i = 0; i < childs.length; ++i) {
                let child = childs[i];
                if (child.tagName === 'title') {
                    let state_name = child.textContent;
                    let state_machine_index_i = index;
                    for (let j = 0; j < childs.length; ++j) {
                        let child_0 = childs[j];
                        if (child_0.tagName === 'polygon' && check_state(state_machine_index_i, state_name) === true) {
                            uncheck_all();
                            child_0.style = "fill:#d0fdf7";
                            go_to_code_state(state_machine_index_i, state_name);
                        }
                    }
                }
            }
        });

        countries[i].addEventListener('click', e => {
            let state_machine_index_i = index;
            let parent_target = e.target.parentNode;
            let childs = parent_target.childNodes;
            for (let i = 0; i < childs.length; ++i) {
                let child = childs[i];
                let transtion = child.textContent.split('->');

                if (child.tagName === 'title' && transtion.length === 2) {
                    let text_count = 0;
                    let condition = '';
                    let child_match;
                    let child_match_0;
                    for (let j = 0; j < childs.length; ++j) {
                        let child_0 = childs[j];
                        if (child_0.tagName === 'text') {
                            if (text_count === 0) {
                                condition = child_0.textContent;
                            }
                            else {
                                condition += '\n' + child_0.textContent;
                            }
                            text_count += 1;
                        }
                        else if (child_0.tagName === 'polygon') {
                            child_match = child_0;
                        }
                        else if (child_0.tagName === 'path') {
                            child_match_0 = child_0;
                        }
                    }
                    if (text_count >= 0) {
                        uncheck_all();
                        child_match.style = "fill:#0024b9;stroke:#0024b9";
                        child_match_0.style = "stroke:#0024b9";
                        go_to_condition(state_machine_index_i, transtion, condition);
                    }
                }
            }
        });

    }
    graph.push(embed);
    document.body.contentEditable = false;
}

function uncheck_all() {
    for (let i = 0; i < graph.length; i++) {
        search_in_tree(graph[i], 'polygon');
        search_in_tree(graph[i], 'path');
    }
}

function check_state(stm_index, state) {
    let states = stms[stm_index].states;
    for (let i = 0; i < states.length; ++i) {
        if (states[i].name.replace(/\"/g, '').replace(/\'/g, '') === state) {
            return true;
        }
    }
    return false;
}


function search_in_tree(element, matchingTitle) {
    let match = undefined;
    function recursive_searchTree(element, matchingTitle) {
        let type = element.tagName;
        if (type === matchingTitle) {
            if (element.style !== undefined && element.style.fill === 'rgb(208, 253, 247)') {
                element.style = "fill:transparent";
            }
            else if (element.style !== undefined && element.style.fill === 'rgb(0, 36, 185)'
                && element.style.stroke === 'rgb(0, 36, 185)') {
                element.style = "fill:#000000;stroke:#000000";
            }
            else if (element.style !== undefined && element.style.stroke === 'rgb(0, 36, 185)') {
                element.style = "fill:none;stroke:#000000";
            }
            match = element;
        } else if (element !== null) {
            let i;
            let result = null;
            let childs = element.childNodes;
            for (i = 0; result === null && i < childs.length; i++) {
                result = recursive_searchTree(childs[i], matchingTitle);
                if (result !== null) {
                    break;
                }
            }
            return result;
        }
        return null;
    }
    recursive_searchTree(element, matchingTitle);
    return match;
}


function go_to_code_state(stm_index, state) {
    vscode.postMessage({
        command: 'go_to_state',
        stm_index: stm_index,
        state: state
    });
}


function go_to_condition(stm_index, transition, condition) {
    vscode.postMessage({
        command: 'go_to_condition',
        stm_index: stm_index,
        transition: transition,
        condition: condition
    });
}

function delete_graph() {
    if (graph === undefined) {
        return;
    }
    for (let i = 0; i < graph.length; ++i) {
        svgPanZoom(graph[i]).destroy();
        if (div[i].parentNode !== null) {
            div[i].parentNode.removeChild(div[i]);
        }
    }
}

let pan_config = {
    zoomEnabled: true,
    controlIconsEnabled: true,
    fit: true,
    center: true,
};

document.getElementById("export-as-svg").onclick = () => { 
    export_message("svg"); 
};

function export_message(message) {
    vscode.postMessage({
        command: 'export',
        text: message
    });
}