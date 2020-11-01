extension APIScope {
    /// https://vk.com/dev/storage
    public enum Stories: APIMethod {
        case getPhotoUploadServer(Parameters)
        case getVideoUploadServer(Parameters)
        case save(Parameters)
    }
}
