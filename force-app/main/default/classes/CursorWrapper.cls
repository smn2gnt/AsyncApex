public class CursorWrapper {
    private String query;
    private transient Database.Cursor cursor;
    private Integer currentPosition;
    private Integer totalRecords;
    private Boolean isInitialized;

    public CursorWrapper(String query) {
        this.query = query;
        this.currentPosition = 0;
        this.totalRecords = -1; // Initialize to indicate not yet fetched
        this.isInitialized = false;
    }

    private void initializeCursor() {
        if (!this.isInitialized) {
            if (String.isBlank(this.query)) {
                // Or throw an exception
                this.totalRecords = 0;
                this.isInitialized = true;
                return;
            }
            this.cursor = Database.getCursor(this.query);
            // Ensure getNumRecords is called only after getCursor
            this.totalRecords = this.cursor.getNumRecords();
            this.isInitialized = true;
        } else if (this.cursor == null && String.isNotBlank(this.query)) {
            // Re-initialize transient cursor if object was deserialized from cache
            this.cursor = Database.getCursor(this.query);
        }
    }

    public List<SObject> fetchNextChunk(Integer chunkSize) {
        initializeCursor();

        if (this.cursor == null || this.currentPosition >= this.totalRecords) {
            return new List<SObject>(); // Return empty list if no cursor or no more records
        }

        List<SObject> records = this.cursor.fetch(this.currentPosition, chunkSize);
        if (records != null) { // fetch can return null
            this.currentPosition += records.size();
        } else {
            // Handle null case, perhaps by returning empty list or logging
            return new List<SObject>();
        }
        return records;
    }

    public Boolean hasMoreRecords() {
        initializeCursor();
        return this.currentPosition < this.totalRecords;
    }

    // Getter methods might be useful for the framework or for debugging
    public String getQuery() {
        return this.query;
    }

    public Integer getCurrentPosition() {
        return this.currentPosition;
    }

    public Integer getTotalRecords() {
        initializeCursor(); // Ensure totalRecords is populated
        return this.totalRecords;
    }

    public Boolean getIsInitialized() {
        return this.isInitialized;
    }

    // Setter for query might be needed if the object is created then query set
    public void setQuery(String query) {
        this.query = query;
        // Reset state if query changes
        this.cursor = null;
        this.currentPosition = 0;
        this.totalRecords = -1;
        this.isInitialized = false;
    }
}
