/* eslint-disable @typescript-eslint/naming-convention */

type Type = {type: string};
type Desc = {description: string};
type Enum<T> = {enum: T[]};
type Default<T> = {default: T};

interface PrjInfoSchema {
    toolChain: Type & Desc & Enum<string>
    prjName: {
        type: string
        default: {
            PL: string
        }
        properties: {
            PL: Type & Desc & Default<string>
            PS: Type & Desc & Default<string>
        }
    }

    arch: {
        type: string
        properties: {
            prjPath: Type
            hardware: {
                type: object
                properties: {
                    src: Type,
                    sim: Type,
                    data: Type
                }
            }
            software: {
                type: string
                properties: {
                    src: Type,
                    data: Type
                }
            }
        }
    }

    library: {
        type: string
        properties: {
            state: Type & Enum<string>
            hardware: {
                type: string
                properties: {
                    common: Type,
                    custom: Type
                }
            }
        }
    }

    IP_REPO: Type

    soc: {
        type: string
        default: {
            core: string
        }
        properties: {
            core: Type & Desc & Enum<string>
            bd: Type & Desc & Enum<string>
            os: Type & Default<string> & Desc & Enum<string>
            app: Type & Default<string> & Desc & Enum<string>
        },
        dependencies: {
            bd: string[]
            os: string[]
            app: string[]
        }
    }

    enableShowLog: Type & Desc & Default<boolean> & Enum<boolean>
    device: Type & Desc & Enum<string>
};

interface PropertySchema {
    title: string
    description: string
    type: string
    properties: PrjInfoSchema
    required: string[]
};

export {
    PrjInfoSchema,
    PropertySchema
};