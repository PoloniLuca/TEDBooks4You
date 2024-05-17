const mongoose = require('mongoose');

const tagSchema = new mongoose.Schema({
    tag: String,
    tag_count: Number,
    videos: Array
}, { _id: false });

const userSchema = new mongoose.Schema({
    name: String, // Puoi aggiungere altre proprietà dell'utente se necessario
    all_tags_info: [tagSchema]
}, { collection: 'tag_from_link_ofe_2' });

module.exports = mongoose.model('User', userSchema);
