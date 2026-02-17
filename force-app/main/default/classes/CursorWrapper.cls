/**
 * Wrapper for Database.Cursor to enable chunked record processing
 * Designed to be stored in Platform Cache with transient cursor field
 */
public class CursorWrapper {
    private String query;
    private transient Database.Cursor cursor;
    private Integer currentPosition;
    private Integer totalRecords;
    private Boolean isInitialized;

    /**
     * Create a new CursorWrapper with a SOQL query
     * @param query The SOQL query to execute
     */
    public CursorWrapper(String query) {
        this.query = query;
        this.currentPosition = 0;
        this.totalRecords = -1;
        this.isInitialized = false;
    }

    /**
     * Initialize the cursor if not already initialized
     * Re-initializes transient cursor after deserialization from cache
     */
    private void initializeCursor() {
        if (!this.isInitialized) {
            if (String.isBlank(this.query)) {
                this.totalRecords = 0;
                this.isInitialized = true;
                return;
            }
            
            try {
                this.cursor = Database.getCursor(this.query);
                this.totalRecords = this.cursor.getNumRecords();
                this.isInitialized = true;
            } catch (Exception ex) {
                throw new AsyncException(AsyncException.ErrorType.CURSOR_ERROR, 'Failed to initialize cursor: ' + ex.getMessage());
            }
        } else if (this.cursor == null && String.isNotBlank(this.query)) {
            // Re-initialize transient cursor if object was deserialized from cache
            try {
                this.cursor = Database.getCursor(this.query);
            } catch (Exception ex) {
                throw new AsyncException(AsyncException.ErrorType.CURSOR_ERROR, 'Failed to re-initialize cursor: ' + ex.getMessage());
            }
        }
    }

    /**
     * Fetch the next chunk of records
     * @param chunkSize Number of records to fetch
     * @return List of SObjects for this chunk
     */
    public List<SObject> fetchNextChunk(Integer chunkSize) {
        if (chunkSize == null || chunkSize <= 0) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Chunk size must be greater than 0');
        }
        
        initializeCursor();

        if (this.cursor == null || this.currentPosition >= this.totalRecords) {
            return new List<SObject>();
        }

        try {
            List<SObject> records = this.cursor.fetch(this.currentPosition, chunkSize);
            if (records != null) {
                this.currentPosition += records.size();
            } else {
                return new List<SObject>();
            }
            return records;
        } catch (Exception ex) {
            throw new AsyncException(AsyncException.ErrorType.CURSOR_ERROR, 'Failed to fetch records: ' + ex.getMessage());
        }
    }

    /**
     * Check if there are more records to process
     * @return true if more records are available
     */
    public Boolean hasMoreRecords() {
        initializeCursor();
        return this.currentPosition < this.totalRecords;
    }

    /**
     * Get the SOQL query
     */
    public String getQuery() {
        return this.query;
    }

    /**
     * Get current position in the record set
     */
    public Integer getCurrentPosition() {
        return this.currentPosition;
    }

    /**
     * Get total number of records
     */
    public Integer getTotalRecords() {
        initializeCursor();
        return this.totalRecords;
    }

    /**
     * Check if cursor is initialized
     */
    public Boolean getIsInitialized() {
        return this.isInitialized;
    }

    /**
     * Set a new query (resets cursor state)
     * @param query The new SOQL query
     */
    public void setQuery(String query) {
        this.query = query;
        this.cursor = null;
        this.currentPosition = 0;
        this.totalRecords = -1;
        this.isInitialized = false;
    }
}
