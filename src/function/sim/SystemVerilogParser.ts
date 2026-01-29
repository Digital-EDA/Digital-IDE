// src/parse-sv.ts
const Parser = require('tree-sitter'); // Parser
const systemverilog = require('tree-sitter-systemverilog'); // Language
const { Query } = require('tree-sitter');

interface Position {
  row: number;
  column: number;
}

interface range {
  start: Position;
  end: Position;
}

interface widthInfo {
  msb: string;
  lsb: string;
}

export interface ModuleInfo {
  name: string;
  range: range;
}

// 端口信息接口
export interface PortInfo {
  range: range;      // 端口在源码中的位置范围
  direction: string; // 端口方向
  type: string;      // 端口类型
  unsigned: boolean; // 符号
  width: widthInfo;  // 位宽信息
  name: string;      // 端口名
}

// 参数信息接口
export interface ParameterInfo {
  range: range;         // 参数在源码中的位置范围
  type: string;         // 参数类型
  unsigned: boolean;    // 符号
  width: widthInfo;     // 位宽信息
  name: string;         // 参数名
  defaultValue: string; // 默认值
}

export class SystemVerilogParser {
  private parser: any;
  private tree: any;
  private rootNode: any;
  public moduleInfo: ModuleInfo = {
    name: '',
    range: { start: { row: 0, column: 0 }, end: { row: 0, column: 0 } }
  };
  public ports: PortInfo[] = [];
  public parameters: ParameterInfo[] = [];

  constructor(code: string) {
    if (typeof code !== 'string') {
      throw new Error('Input code must be a string');
    }
    this.parser = new Parser();
    this.parser.setLanguage(systemverilog);
    this.tree = this.parser.parse(code);
    this.rootNode = this.tree.rootNode;

    // this.printNode(this.rootNode);

    this.moduleInfo = this.extractModuleInfo(this.rootNode);
    // this.printModuleInfo(this.moduleInfo);

    this.ports = this.extractPortInfo(this.rootNode);
    // this.printPorts(this.ports);

    this.parameters = this.extractParameterInfo(this.rootNode);
    // this.printParameters(this.parameters);
  }

  public printNode(node: any, depth = 0): void {
    if (!node || typeof node !== 'object') return;

    const indent = '  '.repeat(depth);
    if (node.isNamed === true)
      console.log(`${indent}${node.type}`);
    else
      console.log(`${indent}${node.type}`, '---> 匿名节点');

    // 安全访问 children：tree-sitter 节点的 children 是数组，但防御性编程更好
    const children = node.children || [];
    for (const child of children) {
      this.printNode(child, depth + 1);
    }
  }

  /**
   * @brief  提取模块信息
   * @param  [void]
   * @return [void]
   */
  private extractModuleInfo(rootNode: any): ModuleInfo {
    const moduleQuery = `
      (module_declaration
        (module_ansi_header
          (module_keyword
            "module"
          )
          (simple_identifier) @module_name
        )
      ) @module_decl
    `;

    const query = new Query(systemverilog, moduleQuery);
    const matches = query.matches(rootNode);
    let moduleInfo: ModuleInfo = {
      name: '',
      range: { start: { row: 0, column: 0 }, end: { row: 0, column: 0 } }
    };

    if (matches.length > 0) {
      const match = matches[0];
      for (const capture of match.captures) {
        const nodeName = capture.name;
        const node = capture.node;

        switch (nodeName) {
          case 'module_decl':
            moduleInfo.range.start = { row: node.startPosition.row, column: node.startPosition.column };
            moduleInfo.range.end = { row: node.endPosition.row, column: node.endPosition.column };
            break;
          case 'module_name':
            moduleInfo.name = node.text;
            break;
        }
      }
    }
    return moduleInfo;
  }

  public printModuleInfo(moduleInfo: ModuleInfo): void {
    console.log(`模块名: ${moduleInfo.name}`);
    console.log(`范围: [${moduleInfo.range.start.row},${moduleInfo.range.start.column}] 到 [${moduleInfo.range.end.row},${moduleInfo.range.end.column}]`);
  }

  /**
   * @brief  提取端口信息
   * @param  [void]
   * @return [void]
   */
  private extractPortInfo(rootNode: any): PortInfo[] {
    const portQuery = `
      (
        (ansi_port_declaration
          (variable_port_header
            (port_direction) @direction
            (variable_port_type
              (data_type
                (integer_vector_type)? @int_vector_type
                "signed"? @signed
                (packed_dimension
                  (constant_range
                    (constant_expression) @msb
                    (constant_expression) @lsb
                  )?
                )?
              )?
            )?
          )
          (simple_identifier) @port_name
        ) @port
      )

      (
        (ansi_port_declaration
          (net_port_header
            (port_direction) @direction
            (net_port_type
              (data_type_or_implicit
                (implicit_data_type
                  "signed"? @signed
                  (packed_dimension
                    (constant_range
                      (constant_expression) @msb
                      (constant_expression) @lsb
                    )?
                  )?
                )?
              )?
            )?
          )
          (simple_identifier) @port_name
        ) @port
      )
    `;

    const query = new Query(systemverilog, portQuery);
    const matches = query.matches(rootNode);
    let portInfoList: PortInfo[] = [];

    for (const match of matches) {
      // console.log('Match found:', match);
      let PortInfo: PortInfo = {
        name: '',
        direction: '',
        unsigned: true,
        width: { msb: '0', lsb: '0' },
        type: 'Default',
        range: { start: { row: 0, column: 0 }, end: { row: 0, column: 0 } }
      }

      for (const capture of match.captures) {
        const nodeName = capture.name;
        const node = capture.node;

        switch (nodeName) {
          case 'port':
            PortInfo.range.start = { row: node.startPosition.row, column: node.startPosition.column };
            PortInfo.range.end = { row: node.endPosition.row, column: node.endPosition.column };
            break;
          case 'direction':
            PortInfo.direction = node.text;
            break;
          case 'port_name':
            PortInfo.name = node.text;
            break;
          case 'msb':
            PortInfo.width.msb = node.text;
            break;
          case 'lsb':
            PortInfo.width.lsb = node.text;
            break;
          case 'signed':
            PortInfo.unsigned = false;
            break;
          case 'int_vector_type':
            // console.log('Data type node text:', node.text);
            PortInfo.type = node.text;
            break;
        }
      }
      portInfoList.push(PortInfo);
    }
    return portInfoList;
  }

  /**
   * @brief  打印端口信息
   * @param  [void]
   * @return [void]
   */
  public printPorts(portInfoList: PortInfo[]): void {
    console.log('端口数量:', portInfoList.length);
    for (const port of portInfoList) {
      console.log(`端口名: ${port.name}`);
      console.log(`  方向: ${port.direction}`);
      console.log(`  类型: ${port.type}`);
      console.log(`  无符号: ${port.unsigned}`);
      console.log(`  宽度: [${port.width.msb}:${port.width.lsb}]`);
      console.log(`  范围: [${port.range.start.row},${port.range.start.column}] 到 [${port.range.end.row},${port.range.end.column}]`);
    }
  }

  /**
   * @brief  提取参数信息
   * @param  [void]
   * @return [void]
   */
  private extractParameterInfo(rootNode: any): ParameterInfo[] {
    const ParameterQuery = `
      (
        ;(parameter_port_declaration
          (parameter_declaration
            "parameter"
            (data_type_or_implicit
              (_
                "signed"? @signed
                "string"? @type
                (packed_dimension
                  (constant_range
                    (constant_expression) @msb
                    (constant_expression) @lsb
                  )?
                )?
              )?
            )?
            (list_of_param_assignments
              (param_assignment
                (simple_identifier) @param_name
                "="
                (constant_param_expression) @default_value
              )
            )
          ) @param
        ;)
      )
    `;

    const query = new Query(systemverilog, ParameterQuery);
    const matches = query.matches(rootNode);
    let paramsList: ParameterInfo[] = [];

    for (const match of matches) {
      // console.log('Match found:', match);
      let paramInfo: ParameterInfo = {
        name: '',
        unsigned: true,
        width: { msb: '0', lsb: '0' },
        type: 'Default',
        defaultValue: '',
        range: { start: { row: 0, column: 0 }, end: { row: 0, column: 0 } }
      }

      for (const capture of match.captures) {
        const nodeName = capture.name;
        const node = capture.node;
        switch (nodeName) {
          case 'param':
            paramInfo.range.start = { row: node.startPosition.row, column: node.startPosition.column };
            paramInfo.range.end = { row: node.endPosition.row, column: node.endPosition.column };
            break;
          case 'param_name':
            paramInfo.name = node.text;
            break;
          case 'msb':
            paramInfo.width.msb = node.text;
            break;
          case 'lsb':
            paramInfo.width.lsb = node.text;
            break;
          case 'signed':
            paramInfo.unsigned = false;
            break;
          case 'default_value':
            paramInfo.defaultValue = node.text;
            break;
          case 'type':
            paramInfo.type = node.text;
            break;
        }
      }
      paramsList.push(paramInfo);
    }
    return paramsList;
  }

  /**
   * @brief  打印参数信息
   * @param  [void]
   * @return [void]
   */
  public printParameters(paramsList: ParameterInfo[]): void {
    console.log('参数数量:', paramsList.length);
    for (const param of paramsList) {
      console.log(`参数名: ${param.name}`);
      console.log(`  类型: ${param.type}`);
      console.log(`  无符号: ${param.unsigned}`);
      console.log(`  宽度: [${param.width.msb}:${param.width.lsb}]`);
      console.log(`  默认值: ${param.defaultValue}`);
      console.log(`  范围: [${param.range.start.row},${param.range.start.column}] 到 [${param.range.end.row},${param.range.end.column}]`);
    }
  }


}
