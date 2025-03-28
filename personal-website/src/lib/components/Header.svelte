<script lang="ts">
  import { smetko } from 'personal-reusables';
</script>

<div class="header">
  <img id="face" src={smetko} alt="Marijan Smetko" />
  <h1 id="name">Marijan Smetko</h1>
</div>

<style scoped lang="css">
  .header {
    padding: 20px 30px;
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: left;
  }

  #name {
    padding-left: 20px;
    font-size: 25px;
  }

  #face {
    object-fit: cover;
    height: 45px;
    border-radius: 3px;
  }

  @media screen and (min-width: 350px) {
    #name {
      font-size: 30px;
    }

    #face {
      height: 50px;
    }
  }
  @media screen and (min-width: 650px) {
    #name {
      font-size: 40px;
    }

    #face {
      height: 70px;
    }
  }
</style>
