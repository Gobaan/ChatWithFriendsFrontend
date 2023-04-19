function speak(text, lang) {
  const synth = window.speechSynthesis;
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = lang;
  synth.speak(utterance);
}

function getSupportedLanguages() {
  const synth = window.speechSynthesis;
  return synth.getVoices().map(voice => voice.lang);
}