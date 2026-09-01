'use strict';

const API = '/api/v1';
const cities = {
  Nagpur: [21.1458, 79.0882],
  Pune: [18.5204, 73.8567],
  Mumbai: [19.0760, 72.8777],
  Hyderabad: [17.3850, 78.4867],
  Delhi: [28.6139, 77.2090],
  Nashik: [19.9975, 73.7898],
  'Chhatrapati Sambhajinagar': [19.8762, 75.3433],
  Amravati: [20.9374, 77.7796],
  Akola: [20.7002, 77.0082],
  Bengaluru: [12.9716, 77.5946],
  Chennai: [13.0827, 80.2707],
  Ahmedabad: [23.0225, 72.5714],
  Surat: [21.1702, 72.8311],
  Bhopal: [23.2599, 77.4126],
  Indore: [22.7196, 75.8577],
};

const state = {
  driver: null,
  trip: null,
  route: null,
  weather: null,
  risk: null,
  co2: null,
  fatigueEvents: 0,
  demoMinutes: 0,
  telemetryFrames: 0,
  socket: null,
  source: null,
  destination: null,
  map: null,
  routeLayer: null,
  markerLayers: [],
};

const $ = (id) => document.getElementById(id);
const els = {};
[
  'splashView','splashButton','appShell','brandHome','backendPill','tripForm','source','destination','driverName','vehicleId','backupDrivers','recentMeal','startButton','setupError',
  'setupView','dashboardView','routeTitle','tripMeta','routeDistance','routeSource','routeDuration','elapsedDuration','mapWrap','routeMap','mapFallback',
  'temperature','weatherCondition','humidity','wind','rain','weatherSource','riskCard','riskLevel','riskScore','riskBar','factorFatigue','factorDuration','factorWeather','factorCircadian',
  'co2Ppm','airQuality','airPrompt','co2Meter','strikeCount','fatigueMessage','simulateFatigueButton','speedValue','earValue','telemetryFatigue','telemetryCount','telemetryButton','telemetryLog',
  'wsStatus','engagementButton','engagementText','engagementLocation','engagementSource','endTripButton','eventLog','clearLogButton','toast','liveDot'
].forEach((id) => { els[id] = $(id); });

function escapeHtml(value) {
  return String(value).replace(/[&<>'"]/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
}

function logEvent(kind, text) {
  const row = document.createElement('div');
  row.className = 'event-row';
  const now = new Date();
  row.innerHTML = `<time>${now.toLocaleTimeString([], {hour:'2-digit', minute:'2-digit', second:'2-digit'})}</time><strong>${escapeHtml(kind)}</strong><span>${escapeHtml(text)}</span>`;
  els.eventLog.prepend(row);
}

function toast(message) {
  els.toast.textContent = message;
  els.toast.classList.add('show');
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => els.toast.classList.remove('show'), 2800);
}

async function api(path, options = {}) {
  const res = await fetch(`${API}${path}`, {
    ...options,
    headers: {'Content-Type':'application/json', ...(options.headers || {})},
  });
  const text = await res.text();
  let body = null;
  if (text) {
    try { body = JSON.parse(text); } catch { body = text; }
  }
  if (!res.ok) {
    const detail = body && typeof body === 'object' ? body.detail : body;
    throw new Error(detail || `HTTP ${res.status}`);
  }
  return body;
}

function populateCities() {
  const names = Object.keys(cities);
  for (const select of [els.source, els.destination]) {
    select.innerHTML = names.map((name) => `<option value="${escapeHtml(name)}">${escapeHtml(name)}</option>`).join('');
  }
  els.source.value = 'Nagpur';
  els.destination.value = 'Hyderabad';
}

async function checkBackend() {
  try {
    const res = await fetch('/health', {cache:'no-store'});
    const data = await res.json();
    if (!res.ok || data.status !== 'ok') throw new Error('Health check failed');
    els.backendPill.className = 'status-pill ok';
    els.backendPill.querySelector('span').textContent = 'Backend online';
  } catch (error) {
    els.backendPill.className = 'status-pill bad';
    els.backendPill.querySelector('span').textContent = 'Backend offline';
  }
}

function openApp() {
  els.appShell.classList.remove('hidden');
  els.splashView.classList.add('leaving');
  setTimeout(() => els.splashView.classList.add('hidden'), 560);
  window.scrollTo({top:0});
}

function resetToSetup() {
  if (state.socket) state.socket.close();
  state.socket = null;
  state.driver = null;
  state.trip = null;
  state.route = null;
  state.weather = null;
  state.risk = null;
  state.co2 = null;
  state.fatigueEvents = 0;
  state.demoMinutes = 0;
  state.telemetryFrames = 0;
  els.dashboardView.classList.add('hidden');
  els.setupView.classList.remove('hidden');
  els.eventLog.innerHTML = '';
  window.scrollTo({top:0, behavior:'smooth'});
}

function setLoading(button, loading, label) {
  button.disabled = loading;
  const textSpan = button.querySelector('span');
  if (label) {
    if (textSpan) textSpan.textContent = label;
    else button.textContent = label;
  }
}

async function startTrip(event) {
  event.preventDefault();
  els.setupError.textContent = '';
  if (els.source.value === els.destination.value) {
    els.setupError.textContent = 'Source and destination must be different.';
    return;
  }
  setLoading(els.startButton, true, 'CREATING LIVE TRIP…');
  try {
    state.source = els.source.value;
    state.destination = els.destination.value;
    const [startLat, startLng] = cities[state.source];
    const [destLat, destLng] = cities[state.destination];

    state.driver = await api('/drivers', {
      method:'POST',
      body:JSON.stringify({name:els.driverName.value.trim(), phone:null, vehicle_id:els.vehicleId.value.trim()}),
    });
    logEvent('DRIVER', `Created driver #${state.driver.id} (${state.driver.vehicle_id}).`);

    state.trip = await api('/trips', {
      method:'POST',
      body:JSON.stringify({driver_id:state.driver.id,start:{latitude:startLat,longitude:startLng},destination:{latitude:destLat,longitude:destLng}}),
    });
    logEvent('TRIP', `Created active trip #${state.trip.id}.`);

    const [route, weather] = await Promise.all([
      api('/routes/calculate', {method:'POST', body:JSON.stringify({start_lat:startLat,start_lng:startLng,destination_lat:destLat,destination_lng:destLng})}),
      api(`/weather?latitude=${encodeURIComponent(startLat)}&longitude=${encodeURIComponent(startLng)}`),
    ]);
    state.route = route;
    state.weather = weather;
    logEvent('ROUTE', `${route.distance_km} km / ${formatMinutes(route.duration_minutes)} (${route.source}).`);
    logEvent('WEATHER', `${weather.temperature}°C, ${weather.condition} (${weather.source}).`);

    els.setupView.classList.add('hidden');
    els.dashboardView.classList.remove('hidden');
    renderJourney();
    await refreshModels();
    connectSocket();
    await loadEngagement();
    window.scrollTo({top:0, behavior:'smooth'});
  } catch (error) {
    els.setupError.textContent = `Could not initialize journey: ${error.message}`;
    logEvent('ERROR', error.message);
  } finally {
    setLoading(els.startButton, false, 'INITIALIZE ROUTING');
  }
}

function formatMinutes(minutes) {
  const total = Math.max(0, Math.round(Number(minutes) || 0));
  const hours = Math.floor(total / 60);
  const mins = total % 60;
  return hours ? `${hours}h ${mins}m` : `${mins}m`;
}

function initMap() {
  if (state.map || !window.L) return;
  state.map = L.map('routeMap', {zoomControl:true, scrollWheelZoom:false});
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap contributors',
  }).addTo(state.map);
}

function clearMapLayers() {
  if (!state.map) return;
  if (state.routeLayer) state.map.removeLayer(state.routeLayer);
  state.routeLayer = null;
  for (const layer of state.markerLayers) state.map.removeLayer(layer);
  state.markerLayers = [];
}

function renderMap(route) {
  const isRoadRoute = route.source === 'osrm' || route.source === 'mapbox';
  if (!isRoadRoute || !window.L) {
    els.routeMap.classList.add('hidden');
    els.mapFallback.classList.remove('hidden');
    return;
  }

  els.mapFallback.classList.add('hidden');
  els.routeMap.classList.remove('hidden');
  initMap();
  clearMapLayers();

  const latLngs = route.geometry.coordinates.map(([lng,lat]) => [Number(lat),Number(lng)]);
  if (latLngs.length < 2) return;
  state.routeLayer = L.polyline(latLngs, {color:'#0754aa', weight:6, opacity:.9, lineJoin:'round'}).addTo(state.map);

  const startIcon = L.divIcon({className:'fader-marker', html:'<span style="display:block;width:18px;height:18px;border-radius:50%;background:#56d4da;border:4px solid white;box-shadow:0 3px 12px rgba(0,0,0,.25)"></span>', iconSize:[18,18], iconAnchor:[9,9]});
  const endIcon = L.divIcon({className:'fader-marker', html:'<span style="display:block;width:18px;height:18px;border-radius:50%;background:#ff5a58;border:4px solid white;box-shadow:0 3px 12px rgba(0,0,0,.25)"></span>', iconSize:[18,18], iconAnchor:[9,9]});
  state.markerLayers.push(L.marker(latLngs[0], {icon:startIcon}).addTo(state.map).bindTooltip(state.source));
  state.markerLayers.push(L.marker(latLngs[latLngs.length-1], {icon:endIcon}).addTo(state.map).bindTooltip(state.destination));
  state.map.fitBounds(state.routeLayer.getBounds(), {padding:[32,32]});
  setTimeout(() => state.map.invalidateSize(), 100);
}

function renderJourney() {
  const r = state.route;
  const w = state.weather;
  els.routeTitle.textContent = `${state.source} → ${state.destination}`;
  els.tripMeta.textContent = `Trip #${state.trip.id} · Driver #${state.driver.id} · ${els.backupDrivers.value} backup driver(s) · recent meal: ${els.recentMeal.value}`;
  els.routeDistance.textContent = `${Number(r.distance_km).toFixed(1)} km`;
  els.routeDuration.textContent = formatMinutes(r.duration_minutes);
  els.routeSource.textContent = r.source === 'osrm' ? 'ROAD ROUTE · OSRM' : r.source === 'mapbox' ? 'ROAD ROUTE · MAPBOX' : 'DISTANCE FALLBACK';
  renderMap(r);

  els.temperature.textContent = Number(w.temperature).toFixed(1);
  els.weatherCondition.textContent = w.condition;
  els.humidity.textContent = `${Number(w.humidity).toFixed(0)}%`;
  els.wind.textContent = `${Number(w.wind_speed).toFixed(1)} km/h`;
  els.rain.textContent = `${Number(w.rain_intensity).toFixed(1)} mm/h`;
  els.weatherSource.textContent = String(w.source).replaceAll('_',' ');
}

async function refreshModels({ear=0.28}={}) {
  if (!state.trip) return;
  const [risk,co2] = await Promise.all([
    api('/risk/calculate', {
      method:'POST',
      body:JSON.stringify({trip_id:state.trip.id,current_ear:ear,recent_fatigue_events:state.fatigueEvents,trip_duration_minutes:state.demoMinutes,weather_condition:state.weather?.condition || 'Clear',rain_intensity:state.weather?.rain_intensity || 0}),
    }),
    api('/co2/predict', {
      method:'POST',
      body:JSON.stringify({trip_id:state.trip.id,duration_minutes:state.demoMinutes,ventilation_factor:1.0}),
    }),
  ]);
  state.risk = risk;
  state.co2 = co2;
  renderRisk();
  renderCo2();
}

function renderRisk() {
  const r = state.risk;
  els.riskLevel.textContent = r.level;
  els.riskScore.textContent = r.score;
  els.riskBar.style.width = `${r.score}%`;
  els.factorFatigue.textContent = Number(r.factors.fatigue_factor).toFixed(1);
  els.factorDuration.textContent = Number(r.factors.duration_factor).toFixed(1);
  els.factorWeather.textContent = Number(r.factors.weather_factor).toFixed(1);
  els.factorCircadian.textContent = Number(r.factors.circadian_factor).toFixed(1);
  els.riskCard.className = `surface risk-card span-4 risk-${String(r.level).toLowerCase()}`;
}

function renderCo2() {
  const c = state.co2;
  els.co2Ppm.textContent = c.estimated_co2_ppm;
  els.airQuality.textContent = c.air_quality_level;
  els.airPrompt.textContent = c.action_prompt;
  els.co2Meter.style.width = `${Math.min(100, Math.max(0, (c.estimated_co2_ppm - 420) / (2500 - 420) * 100))}%`;
  els.elapsedDuration.textContent = `${state.demoMinutes.toFixed(0)} min`;
}

async function simulateFatigue() {
  if (!state.trip) return;
  els.simulateFatigueButton.disabled = true;
  try {
    const [lat,lng] = cities[state.source];
    const event = await api('/fatigue/events', {
      method:'POST',
      body:JSON.stringify({trip_id:state.trip.id,event_type:'MICROSLEEP',severity:'HIGH',ear:0.17,blink_duration_ms:1100,head_pose:'DOWN',latitude:lat,longitude:lng}),
    });
    state.fatigueEvents += 1;
    state.demoMinutes = Math.min(240, state.fatigueEvents * 60);
    els.strikeCount.textContent = Math.min(3,state.fatigueEvents);
    els.fatigueMessage.textContent = `Recorded event #${event.id}. Demo elapsed profile: ${state.demoMinutes} minutes.`;
    await refreshModels({ear:0.17});
    await sendTelemetry({speed:58, ear:0.17, fatigueLevel:state.risk.level, persist:true});
    logEvent('FATIGUE', `HIGH microsleep event #${event.id}; risk updated to ${state.risk.score}/100 ${state.risk.level}.`);
    toast(`Risk updated: ${state.risk.level} (${state.risk.score}/100)`);
  } catch (error) {
    logEvent('ERROR', `Fatigue simulation failed: ${error.message}`);
    toast(`Simulation failed: ${error.message}`);
  } finally {
    els.simulateFatigueButton.disabled = false;
  }
}

function socketUrl() {
  const scheme = location.protocol === 'https:' ? 'wss:' : 'ws:';
  return `${scheme}//${location.host}${API}/ws/trips/${state.trip.id}`;
}

function connectSocket() {
  if (!state.trip) return;
  if (state.socket) state.socket.close();
  try {
    state.socket = new WebSocket(socketUrl());
    els.wsStatus.textContent = 'Connecting…';
    state.socket.addEventListener('open', () => {
      els.wsStatus.textContent = 'Connected';
      logEvent('WEBSOCKET', `Connected to trip #${state.trip.id}.`);
      state.socket.send(JSON.stringify({type:'ping'}));
    });
    state.socket.addEventListener('message', (event) => {
      let data;
      try { data = JSON.parse(event.data); } catch { return; }
      if (data.type === 'pong') { els.wsStatus.textContent = 'Connected · pong'; return; }
      if (data.type === 'trip_update') {
        const speed = Number(data.telemetry?.speed ?? 0);
        const ear = Number(data.telemetry?.ear ?? .28);
        const fatigue = data.fatigue?.level ?? 'LOW';
        els.speedValue.textContent = `${speed.toFixed(0)} km/h`;
        els.earValue.textContent = ear.toFixed(2);
        els.telemetryFatigue.textContent = fatigue;
        els.telemetryLog.textContent = JSON.stringify(data);
      }
    });
    state.socket.addEventListener('close', () => { els.wsStatus.textContent = 'Disconnected'; });
    state.socket.addEventListener('error', () => { els.wsStatus.textContent = 'Error'; });
  } catch (error) {
    els.wsStatus.textContent = 'Unavailable';
    logEvent('ERROR', `WebSocket setup failed: ${error.message}`);
  }
}

async function sendTelemetry({speed=62,ear=0.28,fatigueLevel='LOW',persist=true}={}) {
  if (!state.trip) return;
  const [lat,lng] = cities[state.source];
  state.telemetryFrames += 1;
  const frameSpeed = speed + (state.telemetryFrames % 5);
  if (state.socket?.readyState === WebSocket.OPEN) {
    state.socket.send(JSON.stringify({type:'telemetry',speed:frameSpeed,ear,fatigue_level:fatigueLevel,latitude:lat,longitude:lng}));
  }
  if (persist) {
    try {
      const stored = await api('/telemetry', {method:'POST', body:JSON.stringify({trip_id:state.trip.id,latitude:lat,longitude:lng,speed:frameSpeed,ear,fatigue_level:fatigueLevel})});
      els.telemetryCount.textContent = state.telemetryFrames;
      logEvent('TELEMETRY', `Persisted frame #${stored.id}: ${frameSpeed.toFixed(0)} km/h, EAR ${ear.toFixed(2)}, ${fatigueLevel}.`);
    } catch (error) {
      logEvent('ERROR', `Telemetry persistence failed: ${error.message}`);
    }
  }
}

async function loadEngagement() {
  if (!state.trip) return;
  try {
    const trivia = await api(`/engagement/trivia?location=${encodeURIComponent(state.source)}`);
    els.engagementText.textContent = trivia.fact_or_question;
    els.engagementLocation.textContent = trivia.location;
    els.engagementSource.textContent = String(trivia.source).replaceAll('_',' ');
    logEvent('ENGAGEMENT', `${trivia.location}: ${trivia.fact_or_question}`);
  } catch (error) {
    els.engagementText.textContent = 'Engagement service unavailable.';
    logEvent('ERROR', `Engagement request failed: ${error.message}`);
  }
}

async function endTrip() {
  if (!state.trip) return;
  els.endTripButton.disabled = true;
  try {
    const ended = await api(`/trips/${state.trip.id}/end`, {method:'POST'});
    if (state.socket) state.socket.close();
    state.trip = ended;
    els.tripMeta.textContent = `Trip #${ended.id} · status: ${ended.status} · safely closed in backend`;
    els.wsStatus.textContent = 'Closed';
    els.liveDot.style.background = '#9aa8b5';
    els.endTripButton.textContent = 'NEW JOURNEY';
    els.endTripButton.disabled = false;
    els.endTripButton.onclick = resetToSetup;
    logEvent('TRIP', `Trip #${ended.id} marked completed.`);
    toast('Trip ended and persisted.');
  } catch (error) {
    logEvent('ERROR', `Trip end failed: ${error.message}`);
    toast(`Could not end trip: ${error.message}`);
    els.endTripButton.disabled = false;
  }
}

populateCities();
checkBackend();
els.splashButton.addEventListener('click', openApp);
els.brandHome.addEventListener('click', resetToSetup);
els.tripForm.addEventListener('submit', startTrip);
els.simulateFatigueButton.addEventListener('click', simulateFatigue);
els.telemetryButton.addEventListener('click', () => sendTelemetry({speed:62,ear:.28,fatigueLevel:state.risk?.level || 'LOW',persist:true}));
els.engagementButton.addEventListener('click', loadEngagement);
els.endTripButton.addEventListener('click', endTrip);
els.clearLogButton.addEventListener('click', () => { els.eventLog.innerHTML = ''; });
window.addEventListener('beforeunload', () => { if (state.socket) state.socket.close(); });
