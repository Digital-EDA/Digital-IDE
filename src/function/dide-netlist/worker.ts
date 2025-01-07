import { isMainThread, Worker, parentPort } from 'worker_threads';

if (parentPort) {
    parentPort.on('message', message => {
        const command = message.command as string;
        const data = message.data;

        switch (command) {
            case 'ys':
                
                break;
        
            default:
                break;
        }
    });
}

