const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'sp_phone';
const phone = document.getElementById('phone');
const toast = document.getElementById('toast');
const ownNumber = document.getElementById('own-number');
const conversationList = document.getElementById('conversation-list');
const messageThread = document.getElementById('message-thread');
const messageNumber = document.getElementById('message-number');
const messageBody = document.getElementById('message-body');
const contactList = document.getElementById('contact-list');
const serviceList = document.getElementById('service-list');
const callHistory = document.getElementById('call-history');
const callOverlay = document.getElementById('call-overlay');
const callState = document.getElementById('call-state');
const callNumber = document.getElementById('call-number');
const answerCall = document.getElementById('answer-call');
const declineCall = document.getElementById('decline-call');
const hangupCall = document.getElementById('hangup-call');

let state = {
    number: '',
    contacts: [],
    messages: [],
    calls: [],
    services: [],
    selectedNumber: ''
};
let toastTimer;

async function post(endpoint, payload = {}) {
    const response = await fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    });
    return response.json();
}

function showToast(message) {
    toast.textContent = message;
    toast.classList.remove('hidden');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.add('hidden'), 3200);
}

function displayName(number) {
    const contact = state.contacts.find(entry => entry.phone_number === number);
    return contact ? contact.display_name : number;
}

function formatDate(value) {
    if (!value) return '';
    const date = new Date(String(value).replace(' ', 'T'));
    return Number.isNaN(date.getTime()) ? String(value) : date.toLocaleString('pt-PT', {
        day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit'
    });
}

function makeButton(label, className, onClick) {
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = label;
    if (className) button.className = className;
    button.addEventListener('click', onClick);
    return button;
}

function otherNumber(message) {
    return message.sender_number === state.number ? message.receiver_number : message.sender_number;
}

function setView(viewName) {
    document.querySelectorAll('.tab').forEach(tab => tab.classList.toggle('active', tab.dataset.view === viewName));
    document.querySelectorAll('.view').forEach(view => view.classList.toggle('active', view.id === `view-${viewName}`));
}

function renderConversations() {
    conversationList.replaceChildren();
    const grouped = new Map();

    state.messages.forEach(message => {
        const number = otherNumber(message);
        const existing = grouped.get(number);
        if (!existing || Number(message.id) > Number(existing.id)) grouped.set(number, message);
    });

    [...grouped.entries()]
        .sort((a, b) => Number(b[1].id) - Number(a[1].id))
        .forEach(([number, message]) => {
            const article = document.createElement('article');
            article.tabIndex = 0;
            const title = document.createElement('strong');
            title.textContent = displayName(number);
            const preview = document.createElement('small');
            preview.textContent = message.body;
            article.append(title, preview);
            article.addEventListener('click', () => selectConversation(number));
            conversationList.append(article);
        });
}

function selectConversation(number) {
    state.selectedNumber = number;
    messageNumber.value = number;
    renderThread();
}

function renderThread() {
    const number = state.selectedNumber || messageNumber.value.trim();
    messageThread.replaceChildren();

    if (!number) {
        messageThread.className = 'message-thread empty';
        messageThread.textContent = 'Seleciona uma conversa.';
        return;
    }

    const messages = state.messages
        .filter(message => otherNumber(message) === number)
        .sort((a, b) => Number(a.id) - Number(b.id));

    if (!messages.length) {
        messageThread.className = 'message-thread empty';
        messageThread.textContent = 'Ainda não existem mensagens.';
        return;
    }

    messageThread.className = 'message-thread';
    messages.forEach(message => {
        const bubble = document.createElement('div');
        const outgoing = message.sender_number === state.number;
        bubble.className = `bubble ${outgoing ? 'outgoing' : 'incoming'}`;
        const body = document.createElement('span');
        body.textContent = message.body;
        const time = document.createElement('time');
        time.textContent = formatDate(message.created_at);
        bubble.append(body, time);
        messageThread.append(bubble);
    });
    messageThread.scrollTop = messageThread.scrollHeight;
}

function renderContacts() {
    contactList.replaceChildren();
    state.contacts.forEach(contact => {
        const article = document.createElement('article');
        article.className = 'contact-row';
        const info = document.createElement('div');
        const name = document.createElement('strong');
        name.textContent = contact.display_name;
        const number = document.createElement('small');
        number.textContent = contact.phone_number;
        info.append(name, number);

        const actions = document.createElement('div');
        actions.className = 'row-actions';
        actions.append(
            makeButton('SMS', '', () => {
                selectConversation(contact.phone_number);
                setView('messages');
            }),
            makeButton('Ligar', '', () => startCall(contact.phone_number)),
            makeButton('×', '', async () => {
                const result = await post('deleteContact', { id: contact.id });
                if (!result.ok) return showToast(result.error || 'Não foi possível apagar o contacto.');
                await refresh();
            })
        );
        article.append(info, actions);
        contactList.append(article);
    });
}

function renderServices() {
    serviceList.replaceChildren();
    state.services.forEach(service => {
        const card = document.createElement('article');
        card.className = 'service-card';
        const name = document.createElement('strong');
        name.textContent = `${service.label} · ${service.number}`;
        const online = document.createElement('span');
        online.textContent = `${service.online} profissional${service.online === 1 ? '' : 'is'} online`;
        const button = makeButton('Enviar pedido', 'primary', async () => {
            const body = document.getElementById('service-body').value.trim();
            const result = await post('sendService', { service: service.key, body });
            if (!result.ok) return showToast(result.error || 'Falha ao enviar o pedido.');
            document.getElementById('service-body').value = '';
            showToast(`Pedido enviado para ${service.label}.`);
        });
        card.append(name, online, button);
        serviceList.append(card);
    });
}

function renderCalls() {
    callHistory.replaceChildren();
    const labels = { missed: 'Não atendida', declined: 'Rejeitada', completed: 'Concluída', failed: 'Falhou' };
    state.calls.forEach(call => {
        const incoming = call.receiver_number === state.number;
        const number = incoming ? call.caller_number : call.receiver_number;
        const article = document.createElement('article');
        const title = document.createElement('strong');
        title.textContent = `${incoming ? 'Recebida' : 'Efetuada'} · ${displayName(number)}`;
        const detail = document.createElement('small');
        detail.textContent = `${labels[call.status] || call.status} · ${call.duration_seconds || 0}s · ${formatDate(call.created_at)}`;
        article.append(title, detail);
        article.addEventListener('click', () => startCall(number));
        callHistory.append(article);
    });
}

function renderAll() {
    ownNumber.textContent = state.number || 'SEM NÚMERO';
    renderConversations();
    renderThread();
    renderContacts();
    renderServices();
    renderCalls();
}

async function refresh() {
    const result = await post('refresh');
    if (!result.ok) return showToast(result.error || 'Falha ao atualizar.');
    const selected = state.selectedNumber;
    state = { ...state, ...result, selectedNumber: selected };
    renderAll();
}

async function startCall(number) {
    const target = String(number || '').trim();
    if (!target) return showToast('Indica um número para ligar.');
    const result = await post('startCall', { number: target });
    if (!result.ok) showToast(result.error || 'Não foi possível iniciar a chamada.');
}

function showCall(mode, number) {
    callOverlay.classList.remove('hidden');
    callNumber.textContent = number;
    answerCall.classList.toggle('hidden', mode !== 'incoming');
    declineCall.classList.toggle('hidden', mode !== 'incoming');
    hangupCall.classList.toggle('hidden', mode === 'incoming');
    callState.textContent = mode === 'incoming' ? 'Chamada recebida' : mode === 'connected' ? 'Em chamada' : 'A chamar';
}

function hideCall() {
    callOverlay.classList.add('hidden');
}

document.querySelectorAll('.tab').forEach(tab => tab.addEventListener('click', () => setView(tab.dataset.view)));
document.getElementById('close').addEventListener('click', () => post('close'));
document.getElementById('new-message').addEventListener('click', () => {
    state.selectedNumber = '';
    messageNumber.value = '';
    renderThread();
});
messageNumber.addEventListener('change', () => selectConversation(messageNumber.value.trim()));

document.getElementById('message-form').addEventListener('submit', async event => {
    event.preventDefault();
    const number = messageNumber.value.trim();
    const body = messageBody.value.trim();
    const result = await post('sendMessage', { number, body });
    if (!result.ok) return showToast(result.error || 'Falha ao enviar a mensagem.');
    messageBody.value = '';
    state.selectedNumber = number;
    await refresh();
});

document.getElementById('contact-form').addEventListener('submit', async event => {
    event.preventDefault();
    const nameInput = document.getElementById('contact-name');
    const numberInput = document.getElementById('contact-number');
    const result = await post('addContact', { name: nameInput.value.trim(), number: numberInput.value.trim() });
    if (!result.ok) return showToast(result.error || 'Falha ao guardar o contacto.');
    nameInput.value = '';
    numberInput.value = '';
    await refresh();
});

answerCall.addEventListener('click', async () => {
    const result = await post('answerCall');
    if (!result.ok) showToast(result.error || 'Falha ao atender.');
});
declineCall.addEventListener('click', async () => {
    const result = await post('declineCall');
    if (!result.ok) showToast(result.error || 'Falha ao rejeitar.');
});
hangupCall.addEventListener('click', async () => {
    const result = await post('hangupCall');
    if (!result.ok) showToast(result.error || 'Falha ao desligar.');
});

document.addEventListener('keydown', event => {
    if (event.key === 'Escape' && !phone.classList.contains('hidden')) post('close');
});

setInterval(() => {
    document.getElementById('clock').textContent = new Date().toLocaleTimeString('pt-PT', { hour: '2-digit', minute: '2-digit' });
}, 1000);

window.addEventListener('message', event => {
    const payload = event.data || {};
    if (payload.action === 'open') {
        state = { ...state, ...payload.data, selectedNumber: state.selectedNumber };
        phone.classList.remove('hidden');
        phone.setAttribute('aria-hidden', 'false');
        renderAll();
    } else if (payload.action === 'close') {
        phone.classList.add('hidden');
        phone.setAttribute('aria-hidden', 'true');
        hideCall();
    } else if (payload.action === 'message') {
        state.messages.push(payload.data);
        renderConversations();
        renderThread();
        showToast(`Nova mensagem de ${displayName(payload.data.sender_number)}.`);
    } else if (payload.action === 'incomingCall') {
        showCall('incoming', displayName(payload.number));
    } else if (payload.action === 'outgoingCall') {
        showCall('outgoing', displayName(payload.number));
    } else if (payload.action === 'callConnected') {
        showCall('connected', displayName(payload.number));
    } else if (payload.action === 'callEnded') {
        hideCall();
        showToast('Chamada terminada.');
        refresh();
    } else if (payload.action === 'serviceDispatch') {
        showToast(`[${payload.data.label}] ${payload.data.sender}: ${payload.data.message}`);
    }
});
